import pysolr
import json

class SolrInterface(object):

    def __init__(self, log=None, url=None):
        self.solr_url = url
        self.log = log
        self.solr = self._connect_to_solr()

    def _connect_to_solr(self):
        """
        Connects to Solr using the url provided when object was instantiated.
        """
        return pysolr.Solr(self.solr_url)

    def escape_query(self, raw_query):
        """
        Escape single quotes in value. \
        May or may not be worth a damn at the moment.
        """
        return raw_query.replace("'", "\'")

    def delete_everything(self):
        self.solr.delete(q='*:*')

    def delete_query(self, query, no_confirm=False):
        if not no_confirm:
            s = self.solr.search(self.escape_query(query), **{"rows": "0"})
            are_you_sure = raw_input(
                "Are you sure you want to delete {num_recs} \
                records from Solr? Y/N: ".format(num_recs=s.hits)
            )
            if are_you_sure.lower() == "y":
                self.solr.delete(q=self.escape_query(query))
            else:
                pass#log.debug("Abandon ship! Not deleting anything.")
        else:
            self.solr.delete(q=self.escape_query(query))

    def json_to_dict(self, json_doc):
        j = json.load(open(json_doc, "r"))
        return j

    def add_json_to_solr(self, json_doc):
        record_dict = self.json_to_dict(json_doc)
        self.add_dict_to_solr(record_dict)

    def add_dict_list_to_solr(self, list_of_dicts):
        try:
            self.solr.add(list_of_dicts)
        except pysolr.SolrError as e:
            print("Solr Error: {e}".format(e=e))
