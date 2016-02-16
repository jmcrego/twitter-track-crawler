import json

with open('kk') as f:
    for line in f:
        item = json.loads(line);
        if 'retweeted_status' in item : continue
        if not 'id_str' in item : continue
        print(item['lang']+"\t"+item['id_str']+"\t"+item['created_at']+"\t"+item['user']['screen_name']+"\t"+item['text'])

