# -*- coding: utf-8 -*-
from TwitterAPI import TwitterAPI
import json
from pprint import pprint

CONSUMER_KEY = 'KnzpHso9d7qXfXT72Y0sly360'
CONSUMER_SECRET = 'mQbryk7RInrRp3QZuSkqH4U59H4NsWQj4X8pWFspajklbirCFS'
ACCESS_TOKEN_KEY = '3288314879-pysLtV3l1CnMo3hvRWaGf1KggPQP2xr4SqqcsFy'
ACCESS_TOKEN_SECRET = 'jSGfcnlJAGxZLfbx7CbjGFSDPHP4i7u0NA0UqsU8f60qO'
api = TwitterAPI(CONSUMER_KEY, CONSUMER_SECRET, ACCESS_TOKEN_KEY, ACCESS_TOKEN_SECRET)

TERM_EN = 'start match,first half,second half,end match,extra time,foul,goal,substitution,injury,expulsion,penalty,red card,yellow card,eruption,earthquake,tsunami,flood,tornado,hurricane,typhoon,cyclone,blizzard,hailstorm,wildfire'
#TERM_FR = 'début match,fin match,prolongation,faute,but,remplacement,blessure,penalty,carton jaune,expulsion,éruption,séisme,tsunami,inondation,tornade,ouragan,typhon,cyclone,tempête,grêle,incendie'
#TERM_AR = 'مباراة,المرمى,تسديدة,فريق,ركنية,منتخب,دوري,كأس العالم,بركان,زلزال,تسونامي,عاصفة,اعصار,حريق,زوبعة,بركان,زلازل,اعاصير,زوابع,طوفان,فيضانات,فيضان'

LANGS = {'en':1, 'fr':1, 'ar':1}
LANG = 'en'

r = api.request('statuses/filter', {'track': TERM_EN, 'language': LANG})
#r = api.request('search/tweets', {'q': TERM})

for item in r:
    if 'retweeted_status' in item : continue
    if not 'id_str' in item : continue
#    if not 'lang' in item or not item['lang'] in LANGS : continue
#    print(item['lang']+"\t"+item['id_str']+"\t"+item['created_at']+"\t"+item['user']['screen_name']+"\t"+item['text'])
    print( json.dumps(item, ensure_ascii='True'))
#    print( json.dumps(item, ensure_ascii='True', indent='\t'))



