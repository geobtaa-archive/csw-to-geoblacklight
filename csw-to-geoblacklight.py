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


# non-standard libraries. install via `pip install -r requirements.txt`
from lxml import etree
from owslib import csw
from owslib.etree import etree
from owslib import util
from owslib.namespaces import Namespaces
import unicodecsv as csv
import pysolr
#demjson provides better error messages than json
import demjson
import requests

from config import SOLR_USERNAME, SOLR_PASSWORD, SOLR_URL, CSW_URL, CSW_USER, CSW_PASSWORD, DEBUG
from users import USERS_INSTITUTIONS_MAP

#logging stuff
if DEBUG:
    log_level = logging.DEBUG
else:
    log_level = logging.INFO
global log
log = logging.getLogger('owslib')
log.setLevel(log_level)
ch = logging.StreamHandler(sys.stdout)
ch.setLevel(log_level)
log_formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch.setFormatter(log_formatter)
log.addHandler(ch)


class SolrInterface(object):

    def __init__(self, url, to_spreadsheet=False):
        self.solr_url = url
        self.solr = self._connect_to_solr()

    def _connect_to_solr(self):
        """
        Connects to Solr using the url provided when object was instantiated
        """
        return pysolr.Solr(self.solr_url)

    def escape_query(self, raw_query):
        """
        Escape single quotes in value. May or may not be worth a damn at the moment.
        """
        return raw_query.replace("'","\'")

    def delete_query(self, query, no_confirm=False):
        if not no_confirm:
            s = self.solr.search(self.escape_query(query), **{"rows":"0"})
            are_you_sure = raw_input("Are you sure you want to delete {num_recs} records from Solr? Y/N: ".format(num_recs=s.hits))
            if are_you_sure.lower() == "y":
                self.solr.delete(q=self.escape_query(query))
            else:
                log.debug("Abandon ship! Not deleting anything.")
        else:
            self.solr.delete(q=self.escape_query(query))

    def json_to_dict(self, json_doc):
        j = json.load(open(json_doc, "r"))
        return j

    def add_json_to_solr(self, json_doc):
        record_dict = self.json_to_dict(json_doc)
        self.add_dict_to_solr(record_dict)

    def add_dict_list_to_solr(self, list_of_dicts):
        self.solr.add(list_of_dicts)


class CSWToGeoBlacklight(object):

    def __init__(self, SOLR_URL, SOLR_USERNAME, SOLR_PASSWORD, CSW_URL, CSW_USER, CSW_PASSWORD, USERS_INSTITUTIONS_MAP, TO_CSV=False, max_records=None):

        if SOLR_USERNAME and SOLR_PASSWORD:
            SOLR_URL = SOLR_URL.format(username=SOLR_USERNAME,password=SOLR_PASSWORD)

        self.solr = SolrInterface(SOLR_URL)
        self.XSLT_PATH = os.path.join(".","iso2geoBL.xsl")
        self.transform = etree.XSLT(etree.parse(self.XSLT_PATH))
        self.namespaces = self.get_namespaces()
        self.to_csv = TO_CSV
        self.records = OrderedDict()
        self.record_dicts = []
        self.max_records = max_records
        self.gn_session = None
        self.CSW_USER = CSW_USER
        self.CSW_PASSWORD = CSW_PASSWORD
        self.CSW_URL = CSW_URL
        self.GEONETWORK_BASE = CSW_URL[:CSW_URL.find("/geonetwork/")]
        self.GET_INST_URL = self.GEONETWORK_BASE + "/geonetwork/srv/eng/q?_content_type=json&fast=index&_uuid="
        self.CSV_FIELDNAMES = ["layer_geom_type_s",
            "layer_modified_dt",
            "solr_geom",
            "dct_references_s",
            "dc_rights_s",
            "uuid",
            "dct_provenance_s",
            "dc_subject_sm",
            "dc_description_s",
            "dct_issued_s",
            "dct_temporal_sm",
            "dc_creator_sm",
            "dc_identifier_s",
            "dc_relation_sm",
            "georss_polygon_s",
            "solr_year_i",
            "dc_publisher_sm",
            "layer_id_s",
            "georss_box_s",
            "dc_title_s",
            "dc_format_s",
            'dct_spatial_sm',
            'dct_isPartOf_sm',
            "layer_slug_s",
            'dc_type_s'
            ]

        self.institutions_test = {
            "minn":'"Minnesota"'
        }
        self.institutions = {
            "iowa":'"Iowa"',
            "illinois":'"Illinois"',
            "minn":'"Minnesota"',
            "psu":'"Penn State"',
            "msu":'"Michigan State"',
            "mich":'"Michigan"',
            "purdue":'"Purdue"',
            "umd":'"Maryland"',
            "wisc":'"Wisconsin"'
        }
        self.USERS_INSTITUTIONS_MAP = USERS_INSTITUTIONS_MAP

    @staticmethod
    def get_namespaces():
        """
        Returns specified namespaces using owslib Namespaces function.
        """

        n = Namespaces()
        ns = n.get_namespaces(["gco","gmd","gml","gml32","gmx","gts","srv","xlink","dc"])
        # ns[None] = n.get_namespace("gmd")
        return ns


    def delete_records_institution(self, inst):
        """
        Delete records from Solr.
        TODO make more flexible.
        """
        self.solr.delete_query("dct_provenance_s:" + self.institutions[inst])


    def to_spreadsheet(self, records):
        """
        Transforms CSW XMLs into GeoBlacklight JSON, then writes to a CSV.
        """
        with open("gblout.csv","wb") as out_file:
            writer = csv.DictWriter(out_file, fieldnames=self.CSV_FIELDNAMES)
            writer.writeheader()
            for r in records:
                writer.writerow(r)


    def get_records(self, start_pos=0):

        self.csw_i.getrecords2(esn="full",
            startposition=start_pos,
            maxrecords=50,
            outputschema="http://www.isotc211.org/2005/gmd")

        log.debug(self.csw_i.results)
        self.records.update(self.csw_i.records)

        max_records = self.max_records or self.csw_i.results['matches']

        if self.csw_i.results['matches'] != 0 and self.csw_i.results['nextrecord'] <= max_records:
            start_pos = self.csw_i.results['nextrecord']
            self.get_records(start_pos=start_pos)

    def connect_to_csw(self, url):
        """
        Connect to a CSW using configuration options from config.py.
        """
        if self.CSW_USER and self.CSW_PASSWORD:
            self.csw_i = csw.CatalogueServiceWeb(url, username=CSW_USER, password=CSW_PASSWORD)
        else:
            self.csw_i = csw.CatalogueServiceWeb(url)

    def create_geonetwork_session(self):
        BASE_URL = self.GEONETWORK_BASE+"/srv/eng/"
        LOGIN =  self.GEONETWORK_BASE+"/j_spring_security_check"

        self.gn_session = requests.Session()
        self.gn_session.auth = (self.CSW_USER, self.CSW_PASSWORD)
        login_r = self.gn_session.post(LOGIN, auth=(self.CSW_USER, self.CSW_PASSWORD))

    def destroy_geonetwork_session(self):
        LOGOUT = self.GEONETWORK_BASE+"/j_spring_security_logout"
        self.gn_session.post(LOGOUT)

    def get_inst_for_record(self, record_uuid):
        if not self.gn_session:
            self.create_geonetwork_session()

        url = self.GET_INST_URL+record_uuid
        re = self.gn_session.get(url)
        time.sleep(1)
        js = re.json()
        if js.has_key("metadata"):
            user = js["metadata"]["geonet:info"]["ownerId"]
            if self.USERS_INSTITUTIONS_MAP.has_key(user):
                log.debug("{user} maps to {inst}".format(user=user,
                    inst=self.USERS_INSTITUTIONS_MAP[user]))
                return self.USERS_INSTITUTIONS_MAP[user]
            else:
                log.info("Could not find user in map. Defaulting to Minn.")
                return "minn"


    def transform_records(self, uuids_and_insts=None, inst=None):
        for r in self.records:
            if not inst and not uuids_and_insts:
                inst = self.get_inst_for_record(r)
            elif uuids_and_insts:
                inst = uuids_and_insts[r]
            rec = self.records[r].xml
            rec = rec.replace("\n","")
            root = etree.fromstring(rec)
            record_etree = etree.ElementTree(root)
            result = self.transform(record_etree, institution=self.institutions[inst])
            result_u = unicode(result)
            try:
                result_dict = demjson.decode(result_u)
                log.debug(result_dict)
            except demjson.JSONDecodeError as e:
                log.error("ERROR")
                log.error(result_u)
            self.record_dicts.append(result_dict)

    def records_by_institution(self, inst):
        # s.delete_query("dct_provenance_s:" + institutions[inst])
        url = CSW_URL.format(virtual_csw_name=inst)
        self.inst = inst
        self.connect_to_csw(url)
        self.get_records()
        self.transform_records()
        if self.to_csv:
            self.to_spreadsheet(self.record_dicts)
        else:
            self.solr.add_dict_list_to_solr(self.record_dicts)

    def records_by_csw(self, csw_name, inst=None):
        url = CSW_URL.format(virtual_csw_name=csw_name)
        if inst:
            self.inst = inst
        self.connect_to_csw(url)
        self.get_records()
        self.transform_records()
        if self.to_csv:
            self.to_spreadsheet(self.record_dicts)
        else:
            self.solr.add_dict_list_to_solr(self.record_dicts)


    def update_one_record(self, uuid):
        url = CSW_URL.format(virtual_csw_name="publication")
        self.connect_to_csw(url)
        self.csw_i.getrecordbyid(id=[uuid], outputschema="http://www.isotc211.org/2005/gmd")
        self.records.update(self.csw_i.records)
        rec = self.records[uuid].xml
        rec = rec.replace("\n","")
        root = etree.fromstring(rec)
        record_etree = etree.ElementTree(root)
        inst = self.get_inst_for_record(uuid)
        result = self.transform(record_etree, institution=self.institutions[inst])
        result_u = unicode(result)
        log.debug(result_u)
        try:
            result_dict = demjson.decode(result_u)
            log.debug(result_dict)
        except demjson.JSONDecodeError as e:
            log.error("ERROR")
            log.error(result_u)

        if self.to_csv:
            self.to_spreadsheet(result_dict)
        else:
            self.solr.add_dict_list_to_solr([result_dict])


    def records_by_csv(self, path_to_csv, inst=None):
        with open(path_to_csv,"rU") as f:
            reader = csv.DictReader(f)
            fieldnames = reader.fieldnames
            uuids_and_insts = {}
            url = CSW_URL.format(virtual_csw_name="publication")
            self.connect_to_csw(url)

            for row in reader:
                if "uuid" not in fieldnames:
                    continue

                if inst is None:
                    if "inst" in fieldnames:
                        uuids_and_insts[row["uuid"]] =row["inst"]
                    #TODO use Owner field to determint inst, to cut down on http calls
                    elif "inst" not in fieldnames:
                        uuids_and_insts[row["uuid"]] = self.get_inst_for_record(row["uuid"])
                else:
                    uuids_and_insts[row["uuid"]] = inst

            self.csw_i.getrecordbyid(id=uuids_and_insts.keys(), outputschema="http://www.isotc211.org/2005/gmd")
            self.records.update(self.csw_i.records)
            self.transform_records(uuids_and_insts=uuids_and_insts)

            if self.to_csv:
                self.to_spreadsheet(self.record_dicts)
            else:
                self.solr.add_dict_list_to_solr(self.record_dicts)


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)

    #TODO make spreadsheet output an option for all of the group options below (institution, single csw, single uuid, csv)
    parser.add_argument("-w", "--to_csv", action='store_true', help="Output to CSV instead of GBL.")
    parser.add_argument("-n", "--nstitution", help="The institution to harvest records for.")

    group.add_argument("-p", "--path_to_csv", help="Indicate path to the csv containing the record uuids to update.")
    group.add_argument("-i", "--institution", help="The institution to harvest records for. \
        \nValid values are one of the following : iowa, illinois, mich, minn, msu, psu, purdue, umd, wisc")
    group.add_argument("-s", "--single-record-uuid", help="A single uuid to update")
    group.add_argument("-v", "--single-virtual-csw", help="A virtual csw to harvest records from. Provide the text that follows 'csw-'")
    group.add_argument("-d", "--delete-records-institution", help="Delete records for an instution. \
        \nValid values are one of the following : iowa, illinois, mich, minn, msu, psu, purdue, umd, wisc")
    args = parser.parse_args()
    to_csv = args.to_csv
    print to_csv
    interface = CSWToGeoBlacklight(SOLR_URL, SOLR_USERNAME, SOLR_PASSWORD,
        CSW_URL, CSW_USER, CSW_PASSWORD, USERS_INSTITUTIONS_MAP, TO_CSV=to_csv)

    if args.path_to_csv:
        if args.nstitution:
            interface.records_by_csv(args.path_to_csv, inst=args.nstitution)
        else:
            interface.records_by_csv(args.path_to_csv)

    elif args.institution:
        interface.records_by_institution(args.institution)

    elif args.single_record_uuid:
        interface.update_one_record(args.single_record_uuid)

    elif args.single_virtual_csw:
        interface.records_by_csw(args.single_virtual_csw, inst=raw_input("Enter institution code value. \
            \nValid values are one of the following : iowa, illinois, mich, minn, msu, psu, purdue, umd, wisc: "))

    elif args.delete_records_institution:
        interface.delete_records_institution(args.delete_records_institution)

    else:
        sys.exit("Indicate an institution or a csv containing UUIDs to update.")


if __name__ == "__main__":
    sys.exit(main())
