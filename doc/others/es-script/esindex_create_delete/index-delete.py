#!/usr/bin/python

import datetime
import json
import logging
import re
from datetime import datetime, timedelta
from logging.handlers import TimedRotatingFileHandler
import requests

formatter = logging.Formatter("%(asctime)s [line:%(lineno)d] %(levelname)s %(message)s", "%Y-%m-%d %H:%M:%S")
log_file_handler = logging.handlers.TimedRotatingFileHandler(filename="index-delete", when="D", interval=1,
                                                             backupCount=7)
console = logging.StreamHandler()
log_file_handler.setFormatter(formatter)
console.setFormatter(formatter)
log_file_handler.suffix = '%Y-%m-%d.log'
log_file_handler.extMatch = re.compile(r"\d{4}-\d{2}-\d{2}.log$")
logger = logging.getLogger('log')
logger.setLevel(logging.DEBUG)
console.setLevel(logging.DEBUG)
logger.addHandler(log_file_handler)
logger.addHandler(console)

CONNECT_ES_TIMEOUT = 30
PRD_MAX_KEEP_TIME = 10

#要保留的索引加到这里,例 '12-12','11-11'
excludeIndexList = []


def delete(cluster_addr, index_prefix, keep_days, exclude):
    logger.info('begin delete index: cluster=%s, indexPrefix=%s, keepDays=%d, exclude=%s'
                % (cluster_addr, index_prefix, keep_days, exclude))
    index_list = get_delete_index(index_prefix, keep_days, exclude)
    for index in index_list:
        url = cluster_addr + '/' + index
        logger.info(url)
        delete_request(url)


def delete_request(url):
    try:
        rsp = requests.delete(url)
    except BaseException as e:
        exceptionMsg = 'delete request ' + url + 'is warning ' + str(e.args)
        logger.warn(exceptionMsg)
    else:
        content = bytes.decode(rsp.content)
        logger.info('delete request ' + url + ', respose is :' + content)


def get_delete_index(indexPrefix, keepDays, exclude):
    deleteIndexList = []
    now = datetime.now()
    for i in range(keepDays, PRD_MAX_KEEP_TIME):
        date = now - timedelta(days=i)
        indexName = indexPrefix + '-' + date.strftime('%Y-%m-%d') + '*'
        if not checkIfExclude(indexName, exclude):
            deleteIndexList.append(indexName)
    return deleteIndexList


def checkIfExclude(indexName, exclude):
    for item in exclude:
        if item in indexName:
            return True
    return False


with open('/opt/python/index-delete.json') as f:
    config = json.loads(''.join(f.readlines()))

cluster_list = config['cluster']
index_list = config['index']

for cluster in cluster_list:
    logger.info("begin delete index on: %s" % (cluster['id']))
    for index in index_list:
        year = datetime.now().year
        excludeList = []
        for e in excludeIndexList:
            if len(e) == 5:
                excludeList.append("%d-%s" % (year, e))
                excludeList.append("%d-%s" % (year-1, e))
            else:
                excludeList.append(e)
        if 'exclude' in index:
            exclude = index['exclude']
            for e in exclude:
                if len(e) == 5:
                    excludeList.append("%d-%s" % (year, e))
                    excludeList.append("%d-%s" % (year - 1, e))
                else:
                    excludeList.append(e)
        delete(cluster['addr'], index['prefix'], index['keep_days'], excludeList)



