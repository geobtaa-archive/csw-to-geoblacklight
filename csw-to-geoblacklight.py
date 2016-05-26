#! /usr/bin/env python
import os
from glob import glob
import json
import sys
from collections import OrderedDict
import argparse
import pdb
import pprint

import unicodecsv as csv
import pysolr
import demjson
from lxml import etree
from owslib import csw
from owslib.etree import etree
from owslib import util
from owslib.namespaces import Namespaces

from config import SOLR_USERNAME, SOLR_PASSWORD, SOLR_URL, CSW_URL, CSW_USER, CSW_PASSWORD

records = OrderedDict()
record_dicts = []
XSLT_PATH = os.path.join(".","iso2geoBL.xsl")

institutions_test = {
    "minn":'"University of Minnesota"'
}
institutions = {
    "iowa":'"University of Iowa"',
    "illinois":'"University of Illinois"',
    "minn":'"University of Minnesota"',
    "psu":'"Penn State University"',
    "msu":'"Michigan State University"',
    "mich":'"University of Michigan"',
    "purdue":'"Purdue University"',
    "umd":'"University of Maryland"',
    "wisc":'"University of Wisconsin-Madison"'
}


class SolrInterface(object):

    def __init__(self, url="http://54.235.211.28:8080/solr/collection1/"):
        # defaults to UMN OGP
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
                print "Abandon ship!"
        else:
            self.solr.delete(q=self.escape_query(query))

    def json_to_dict(self, json_doc):
        j = json.load(open(json_doc, "r"))
        return j

    def add_json_to_solr(self,json_doc):
        record_dict = self.json_to_dict(json_doc)
        self.add_dict_to_solr(record_dict)

    def add_dict_list_to_solr(self, list_of_dicts):
        self.solr.add(list_of_dicts)

s = SolrInterface(SOLR_URL)
transform = etree.XSLT(etree.parse(XSLT_PATH))

def get_namespaces():
    """
    Returns specified namespaces using owslib Namespaces function.
    """

    n = Namespaces()
    ns = n.get_namespaces(["gco","gmd","gml","gml32","gmx","gts","srv","xlink","dc"])
    ns[None] = n.get_namespace("gmd")
    return ns

namespaces = get_namespaces()

def records_by_institution(inst):
    # s.delete_query("dct_provenance_s:" + institutions[inst])
    url = CSW_URL.format(institution=inst)
    csw_i = csw.CatalogueServiceWeb(url, username=CSW_USER, password=CSW_PASSWORD)

    start_pos = 0
    csw_i.getrecords2(esn="full", startposition=start_pos, maxrecords=100,outputschema="http://www.isotc211.org/2005/gmd")
    print inst, csw_i.results
    records.update(csw_i.records)

    while csw_i.results['matches'] != 0 and csw_i.results['nextrecord'] <= csw_i.results['matches']:
        start_pos = csw_i.results['nextrecord']
        csw_i.getrecords2(esn="full", startposition=start_pos, maxrecords=100,outputschema="http://www.isotc211.org/2005/gmd")
        print inst, csw_i.results
        records.update(csw_i.records)

    for r in records:
        # print r
        rec = records[r].xml
        rec = rec.replace("\n","")
        root = etree.fromstring(rec)
        record_etree = etree.ElementTree(root)
        result = transform(record_etree, institution=institutions[inst])
        # print result
        result_u = unicode(result)
        result_dict = demjson.decode(result_u)
        #result_dict = json.loads(result_u)
        record_dicts.append(result_dict)

    s.add_dict_list_to_solr(record_dicts)


def update_one_record(uuid):
    csw_i = csw.CatalogueServiceWeb(CSW_URL.format(institution="publication"), username=CSW_USER, password=CSW_PASSWORD)
    csw_i.getrecordbyid(id=[uuid], outputschema="http://www.isotc211.org/2005/gmd")
    records.update(csw_i.records)
    rec = records[uuid].xml
    rec = rec.replace("\n","")
    root = etree.fromstring(rec)
    record_etree = etree.ElementTree(root)
    result = transform(record_etree, institution=institutions["minn"])
    # print result
    result_u = unicode(result)
    pprint.pprint(result_u)
    result_dict = demjson.decode(result_u)

    # import pdb; pdb.set_trace()
    s.add_dict_list_to_solr([result_dict])

def records_by_csv(path_to_csv):
    with open(path_to_csv,"rU") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        uuids_and_insts = {}

        csw_i = csw.CatalogueServiceWeb(CSW_URL.format(institution="publication"), username=CSW_USER, password=CSW_PASSWORD)

        for row in reader:
            uuids_and_insts[row["uuid"]] =row["inst"]

        csw_i.getrecordbyid(id=uuids_and_insts.keys(), outputschema="http://www.isotc211.org/2005/gmd")
        records.update(csw_i.records)


        for r in records:
            print r
            rec = records[r].xml
            rec = rec.replace("\n","")
            root = etree.fromstring(rec)
            record_etree = etree.ElementTree(root)
            result = transform(record_etree, institution=institutions[uuids_and_insts[r]])
            # print result
            result_u = unicode(result)
            #pprint.pprint(result_u)
            result_dict = demjson.decode(result_u)

            # import pdb; pdb.set_trace()
            s.add_dict_list_to_solr([result_dict])
            #result_dict = json.loads(result_u)
            #record_dicts.append(result_dict)

        #s.add_dict_list_to_solr(record_dicts)


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("-p", "--path_to_csv", help="Indicate path to the csv containing the record uuids to update.")
    group.add_argument("-i", "--institution", help="The institution to harvest records for. \
        Valid values are one of the following : iowa, illinois, mich, minn, msu, psu, purdue, umd, wisc")
    group.add_argument("-s", "--single-record-uuid", help="A single uuid to update")
    args = parser.parse_args()
    #s.delete_query("dct_provenance_s:" + institutions["minn"])
    if args.path_to_csv:
        records_by_csv(args.path_to_csv)

    elif args.institution:
        records_by_institution(args.institution)

    elif args.single_record_uuid:
        update_one_record(args.single_record_uuid)

    else:
        sys.exit("Indicate an institution or a csv containing UUIDs to update.")

    # s = SolrInterface(url=SOLR_URL.format(username=USERNAME, password=PASSWORD))
    #s = SolrInterface(url="https://user:pass@lib-geoblacklightdev.oit.umn.edu:8983/solr/blacklight-core/")
    # s.delete_query("*:*")


if __name__ == "__main__":
    sys.exit(main())
