#! /usr/bin/env python
import os
from glob import glob
import json
import sys
from collections import OrderedDict
import argparse
import pdb
import pprint
import time
import logging
import fnmatch
import urllib

# non-standard libraries. install via `pip install -r requirements.txt`
from lxml import etree
from owslib import csw
from owslib.etree import etree
from owslib import util
from owslib.namespaces import Namespaces
import unicodecsv as csv
# demjson provides better error messages than json
import demjson
import requests

# local imports
from solr_interface import SolrInterface
import config
from users import USERS_INSTITUTIONS_MAP

# logging stuff
if config.DEBUG:
    log_level = logging.DEBUG
else:
    log_level = logging.INFO
global log
log = logging.getLogger('owslib')
log.setLevel(log_level)
ch = logging.StreamHandler(sys.stdout)
ch.setLevel(log_level)
log_formatter = logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
ch.setFormatter(log_formatter)
log.addHandler(ch)



class CSWToGeoBlacklight(object):

    def __init__(self, SOLR_URL, SOLR_USERNAME, SOLR_PASSWORD, CSW_URL,
                 CSW_USER, CSW_PASSWORD, USERS_INSTITUTIONS_MAP, INST=None,
                 TO_CSV=False, TO_JSON=False, TO_XML=False, TO_XMLs=False, TO_OGM=False,
                 max_records=None, COLLECTION=None, RECURSIVE=False,
                 MD_LINK=False):

        if SOLR_USERNAME and SOLR_PASSWORD:
            SOLR_URL = SOLR_URL.format(
                username=SOLR_USERNAME,
                password=SOLR_PASSWORD
            )

        self.solr = SolrInterface(log=log, url=SOLR_URL)
        self.XSLT_PATH = os.path.join(".", "iso2geoBL.xsl")
        self.transform = etree.XSLT(etree.parse(self.XSLT_PATH))
        self.namespaces = self.get_namespaces()
        self.to_csv = TO_CSV
        self.to_json = TO_JSON
        self.to_xml = TO_XML
        self.to_xmls = TO_XMLs
        self.md_link = MD_LINK
        self.OPENGEOMETADATA_URL = "https://opengeometadata.github.io/{repo}/{uuid_path}/iso19139.xml"
        self.to_opengeometadata = TO_OGM
        self.inst = INST
        self.records = OrderedDict()
        self.record_dicts = OrderedDict()
        self.max_records = max_records
        self.gn_session = None

        if COLLECTION:
            self.collection = '"' + COLLECTION + '"'
        else:
            self.collection = None
        self.CSW_USER = CSW_USER
        self.CSW_PASSWORD = CSW_PASSWORD
        self.CSW_URL = CSW_URL
        self.RECURSIVE = RECURSIVE
        self.PREFIX = "urn-"
        self.LANG = "eng"
        self.GEONETWORK_BASE = CSW_URL[:CSW_URL.find("/geonetwork/")]
        self.GEONETWORK_SEARCH_BASE = self.GEONETWORK_BASE \
            + "/geonetwork/srv/{l}/q?_content_type=json".format(l=self.LANG)
        self.GEONETWORK_BY_CAT = self.GEONETWORK_SEARCH_BASE \
            + "&fast=index&_cat={category}"
        self.GET_INST_URL = self.GEONETWORK_SEARCH_BASE \
            + "&fast=index&_uuid={uuid}"
        self.CSV_FIELDNAMES = [
            "uuid",
            "dct_provenance_s",
            'dct_isPartOf_sm',
            "layer_slug_s"
        ]

        self.institutions_test = {
            "minn": '"Minnesota"'
        }
        self.institutions = {
            "iowa": '"Iowa"',
            "illinois": '"Illinois"',
            "minn": '"Minnesota"',
            "psu": '"Penn State"',
            "msu": '"Michigan State"',
            "mich": '"Michigan"',
            "purdue": '"Purdue"',
            "umd": '"Maryland"',
            "wisc": '"Wisconsin"',
            "indiana": '"Indiana"'
        }

        self.collection = {
            "clay": '"Clay County GIS Data"',
            "ramsey": '"Open Ramsey County"',
            "mdimap": '"Maryland iMap"',
            "purdue": '"Purdue Georeferenced Imagery"'

        }


        self.USERS_INSTITUTIONS_MAP = USERS_INSTITUTIONS_MAP

    @staticmethod
    def get_namespaces():
        """
        Returns specified namespaces using owslib Namespaces function.
        """

        n = Namespaces()
        ns = n.get_namespaces(["gco", "gmd", "gml", "gml32", "gmx", "gts",
                               "srv", "xlink", "dc"])
        # ns[None] = n.get_namespace("gmd")
        return ns

    def get_files_from_path(self, start_path, criteria="*"):
        files = []

        if self.RECURSIVE:
            for path, folder, ffiles in os.walk(start_path):
                for i in fnmatch.filter(ffiles, criteria):
                    files.append(os.path.join(path, i))
        else:
            files = glob(os.path.join(start_path, criteria))
        return files

    def add_json(self, path_to_json):
        files = self.get_files_from_path(path_to_json, criteria="*.json")
        log.debug(files)
        dicts = []
        for i in files:
            dicts.append(self.solr.json_to_dict(i))
        self.solr.add_dict_list_to_solr(dicts)
        log.info("Added {n} records to solr.".format(n=len(dicts)))

    def delete_records_institution(self, inst):
        """
        Delete records from Solr.
        TODO make more flexible.
        """
        self.solr.delete_query("dct_provenance_s:" + self.institutions[inst])

    def delete_records_collection(self, collection):
        """
        Delete records from Solr.
        """
        self.solr.delete_query("dct_isPartOf_sm:" + self.collection[collection])

    def to_spreadsheet(self, records):
        """
        Transforms CSW XMLs into GeoBlacklight JSON, then writes to a CSV.
        """
        with open("gblout.csv", "wb") as out_file:
            writer = csv.DictWriter(out_file, fieldnames=self.CSV_FIELDNAMES)
            writer.writeheader()
            for r in records:
                writer.writerow(records[r])

    def get_records_by_ids(self, ids):
        recordcount = 0
        for group in self.chunker(ids, 100):
            log.info("Requested {n} records from CSW so far".format(
                n=str(recordcount)
            ))
            recordcount = recordcount + 100
            self.csw_i.getrecordbyid(
                id=group,
                outputschema="http://www.isotc211.org/2005/gmd")
            self.records.update(self.csw_i.records)

    def get_records(self, start_pos=0, ids=None):

        if ids:
            self.get_records_by_ids(ids)
            return

        self.csw_i.getrecords2(
            esn="full",
            startposition=start_pos,
            maxrecords=100,
            outputschema="http://www.isotc211.org/2005/gmd"
        )

        log.debug(self.csw_i.results)
        self.records.update(self.csw_i.records)

        max_records = self.max_records or self.csw_i.results['matches']

        if self.csw_i.results['matches'] != 0 and \
                self.csw_i.results['nextrecord'] <= max_records:
            start_pos = self.csw_i.results['nextrecord']
            self.get_records(start_pos=start_pos)

    def connect_to_csw(self, url):
        """
        Connect to a CSW using configuration options from config.py.
        """
        if self.CSW_USER and self.CSW_PASSWORD:
            self.csw_i = csw.CatalogueServiceWeb(
                url,
                username=self.CSW_USER,
                password=self.CSW_PASSWORD)
        else:
            self.csw_i = csw.CatalogueServiceWeb(url)

    def create_geonetwork_session(self):
        """
        Log into GeoNetwork. Used for non-CSW actions, like searching by
        category or fetching the owner of a record.
        """
        BASE_URL = self.GEONETWORK_BASE+"/srv/eng/"
        LOGIN = self.GEONETWORK_BASE+"/j_spring_security_check"

        self.gn_session = requests.Session()
        self.gn_session.auth = (self.CSW_USER, self.CSW_PASSWORD)
        login_r = self.gn_session.post(LOGIN)

    def destroy_geonetwork_session(self):
        LOGOUT = self.GEONETWORK_BASE+"/j_spring_security_logout"
        self.gn_session.post(LOGOUT)

    def get_inst_for_record(self, record_uuid):
        if not self.gn_session:
            self.create_geonetwork_session()

        url = self.GET_INST_URL.format(uuid=record_uuid)
        re = self.gn_session.get(url)
        time.sleep(1)
        js = re.json()
        if "metadata" in js:
            user = js["metadata"]["geonet:info"]["ownerId"]
            if user in self.USERS_INSTITUTIONS_MAP:
                log.debug("{user} maps to {inst}".format(user=user,
                          inst=self.USERS_INSTITUTIONS_MAP[user]))
                return self.USERS_INSTITUTIONS_MAP[user]
            else:
                log.info("Could not find user in map. Defaulting to Minn.")
                return "minn"

    @staticmethod
    def get_uuid_path(uuid):
        uuid_r = uuid.replace("-","")
        return uuid_r[0:2] + "/" + uuid_r[2:4] + "/" + uuid_r[4:6] + "/" + uuid_r[6:]

    def transform_records(self, uuids_and_insts=None):
        """
        Transforms a set of ISO19139 records into GeoBlacklight JSON.
        Uses iso2geoBL.xsl to perform the transformation.
        """
        inst = self.inst
        for r in self.records:
            if not inst and not uuids_and_insts:
                inst = self.get_inst_for_record(r)
            elif uuids_and_insts:
                inst = uuids_and_insts[r]
            rec = self.records[r].xml
            rec = rec.replace("\n", "")
            root = etree.fromstring(rec)
            record_etree = etree.ElementTree(root)

            if self.collection:
                result = self.transform(
                    record_etree,
                    institution=self.institutions[inst],
                    collection=self.collection
                )
            else:
                result = self.transform(
                    record_etree,
                    institution=self.institutions[inst]
                )

            result_u = unicode(result)
            # A dirty hack to avoid XSLT quagmire WRT skipping non-HTTPS links :{}
            result_u = result_u.replace(",}","}").replace("{,", "{")

            try:
                result_json = demjson.decode(result_u)
                if self.md_link:
                    refs =  demjson.decode(result_json["dct_references_s"])
                    refs["http://www.isotc211.org/schemas/2005/gmd/"] = self.OPENGEOMETADATA_URL.format(
                        repo=self.opengeometadata_map[inst],
                        uuid_path=self.get_uuid_path(r))
                    result_json["dct_references_s"] = demjson.encode(refs)
                result_dict = OrderedDict({r: result_json})
                log.debug(result_dict)
                self.record_dicts.update(result_dict)
            except demjson.JSONDecodeError as e:
                log.error("ERROR: {e}".format(e=e))
                log.error(result_u)


    def records_by_institution(self, inst):
        """
        Requests all records for a given institution. Expects a
        GeoNetwork virtual CSW named csw-{inst}, where {inst} corresponds
        to a key in self.institutions.
        """
        url = self.CSW_URL.format(virtual_csw_name=inst)
        self.inst = inst
        self.connect_to_csw(url)
        self.get_records()
        self.transform_records()
        self.handle_transformed_records()

    def records_by_csw(self, csw_name):
        url = self.CSW_URL.format(virtual_csw_name=csw_name)
        self.connect_to_csw(url)
        self.get_records()
        self.transform_records()
        self.handle_transformed_records()

    def update_one_record(self, uuid):
        url = self.CSW_URL.format(virtual_csw_name="publication")
        self.connect_to_csw(url)
        self.csw_i.getrecordbyid(
            id=[uuid],
            outputschema="http://www.isotc211.org/2005/gmd"
        )
        self.records.update(self.csw_i.records)
        rec = self.records[uuid].xml
        rec = rec.replace("\n", "")
        root = etree.fromstring(rec)
        record_etree = etree.ElementTree(root)
        inst = self.get_inst_for_record(uuid)
        result = self.transform(
            record_etree,
            institution=self.institutions[inst]
        )
        result_u = unicode(result)
        log.debug(result_u)
        try:
            self.record_dicts = OrderedDict({uuid: demjson.decode(result_u)})
            log.debug(self.record_dicts)
        except demjson.JSONDecodeError as e:
            log.error("ERROR: {e}".format(e=e))
            log.error(result_u)

        self.handle_transformed_records()

    @staticmethod
    def chunker(seq, size):
        if sys.version_info.major == 3:
            return (seq[pos:pos + size] for pos in range(0, len(seq), size))
        elif sys.version_info.major == 2:
            return (seq[pos:pos + size] for pos in xrange(0, len(seq), size))

    def handle_transformed_records(self, output_path="./output"):
        log.debug("Handling {n} records.".format(n=len(self.record_dicts)))

        if self.to_csv:
            self.to_spreadsheet(self.record_dicts)

        elif self.to_json:
            self.output_json(output_path)

        elif self.to_xml:
            self.output_xml(output_path)

        elif self.to_xmls:
            self.single_xml(output_path)

        elif self.to_opengeometadata:
            self.output_json(self.to_opengeometadata)
            self.output_xml(self.to_opengeometadata)
            self.output_layers_json(self.to_opengeometadata)

        else:
            self.solr.add_dict_list_to_solr(self.record_dicts.values())
            log.info("Added {n} records to Solr.".format(
                n=len(self.record_dicts)
            ))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-r",
        "--recursive",
        action='store_true',
        help="If input involves a folder, recurse into subfolders.")
    parser.add_argument(
        "-pi",
        "--provenance-institution",
        help="The institution to assign dct_provenance_s to. If provided, this \
            will speed things up. But make sure it's applicable to _all_ \
            records involved. Valid values are one of the following : iowa, \
            illinois, mich, minn, msu, psu, purdue, umd, wisc")
    parser.add_argument(
        "-c",
        "--collection",
        help="The collection name (dc_collection) to use for these records. \
            Added as XSL param")

    output_group = parser.add_mutually_exclusive_group(required=False)


    group = parser.add_mutually_exclusive_group(required=True)

    group.add_argument(
        "-d",
        "--delete-records-institution",
        help="Delete records for an instution.\n\
              Valid values are one of the following : \
              iowa, illinois, mich, minn, msu, psu, purdue, umd, wisc")

    group.add_argument(
        "-dc",
        "--delete-records-collection",
        help="Delete records for an collection.\n\
              Enter the collection name")

    args = parser.parse_args()
    interface = CSWToGeoBlacklight(
        config.SOLR_URL, config.SOLR_USERNAME, config.SOLR_PASSWORD,
        config.CSW_URL, config.CSW_USER, config.CSW_PASSWORD,
        USERS_INSTITUTIONS_MAP, INST=args.provenance_institution,
        COLLECTION=args.collection)


    if args.delete_records_institution:
        interface.delete_records_institution(args.delete_records_institution)

    elif args.delete_records_collection:
        interface.delete_records_collection(args.delete_records_collection)

    else:
        sys.exit(parser.print_help())

    if interface.gn_session:
        interface.destroy_geonetwork_session()


if __name__ == "__main__":
    sys.exit(main())
