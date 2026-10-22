"""Create/update the authorized GitHub development board without duplicating cards."""
import json
from pathlib import Path
from github_admin import api,REPO

ROOT=Path(__file__).resolve().parents[1]
BASE='https://github.com/'+REPO

def graphql(query,variables=None):
    result,_=api('/graphql','POST',{'query':query,'variables':variables or {}})
    if result.get('errors'):raise RuntimeError(json.dumps(result['errors'],ensure_ascii=False))
    return result['data']

def main():
    releases,_=api('/repos/'+REPO+'/releases?per_page=30')
    release=next((entry for entry in releases if entry['tag_name']=='v1.0.0' and not entry['draft']),None)
    required_assets={'The-Mossbound-Atlas-1.0.0-Windows-x64.zip','The-Mossbound-Atlas-1.0.0-Windows-x64.zip.sha256'}
    published=bool(release and required_assets.issubset({asset['name'] for asset in release['assets'] if asset['state']=='uploaded' and asset['size']>0}))
    ci_receipt=ROOT/'verification/hosted_ci.json'
    ci=json.loads(ci_receipt.read_text(encoding='utf-8')) if ci_receipt.exists() else {}
    validated=ci.get('conclusion')=='success' and len(ci.get('jobs',[]))==5 and all(job['conclusion']=='success' for job in ci['jobs'])
    rules,_=api('/repos/'+REPO+'/rulesets/11494557')
    protected=rules['enforcement']=='active' and not rules.get('bypass_actors') and {'pull_request','required_status_checks','required_linear_history','deletion','non_fast_forward'}.issubset({rule['type'] for rule in rules['rules']})
    data=graphql('query { viewer { id projectsV2(first: 50) { nodes { id title url } } } repository(owner:"ProgrammingWithYagle",name:"Open_World_Survival_RPG_CODEX") { id } }')
    project=next((node for node in data['viewer']['projectsV2']['nodes'] if node['title']=='The Mossbound Atlas'),None)
    if project is None:
        project=graphql('mutation($owner:ID!){createProjectV2(input:{ownerId:$owner,title:"The Mossbound Atlas"}){projectV2{id title url}}}',{'owner':data['viewer']['id']})['createProjectV2']['projectV2']
    project_id=project['id']
    readme=f'''# The Mossbound Atlas

Development and player feedback for an offline pixel art wilderness RPG.

The release includes five regions, 143 items, 115 recipes, 41 building pieces, 25 creatures, 30 discovery sites and eight travelers. Independent difficulty/death settings, persistent worlds, five languages and original art/audio are implemented.

[Source]({BASE}) · [Wiki]({BASE}/wiki) · [Downloads]({BASE}/releases) · [Verification]({BASE}/blob/main/docs/IMPLEMENTATION_STATUS.md)

Completed cards describe verified implemented work. The publication card changes to Done only when the Windows download and checksum are public and main protection is active. Follow-up cards cover player testing and improvements; they are not claims of features already shipped.
'''
    graphql('mutation($id:ID!,$readme:String!){updateProjectV2(input:{projectId:$id,public:true,shortDescription:"Development and player feedback for The Mossbound Atlas, an offline pixel art wilderness RPG.",readme:$readme}){projectV2{id}}}',{'id':project_id,'readme':readme})
    graphql('mutation($project:ID!,$repo:ID!){linkProjectV2ToRepository(input:{projectId:$project,repositoryId:$repo}){repository{id}}}',{'project':project_id,'repo':data['repository']['id']})
    board=graphql('query($id:ID!){node(id:$id){... on ProjectV2{fields(first:20){nodes{... on ProjectV2SingleSelectField{id name options{id name}}}} items(first:100){nodes{id content{... on DraftIssue{title}}}}}}}',{'id':project_id})['node']
    status=next(field for field in board['fields']['nodes'] if field.get('name')=='Status')
    options={option['name'].lower():option['id'] for option in status['options']}
    existing={node['content']['title']:node['id'] for node in board['items']['nodes'] if node.get('content') and node['content'].get('title')}
    # The aggregate item list can be empty immediately after successful writes.
    # Verify the saved item IDs directly before considering new draft cards.
    receipt_path=ROOT/'verification/project_publication.json'
    if receipt_path.exists():
        prior=json.loads(receipt_path.read_text(encoding='utf-8'))
        if prior.get('id')==project_id:
            ids=[card['id'] for card in prior.get('cards',[])]
            if ids:
                recorded=graphql('query($ids:[ID!]!){nodes(ids:$ids){... on ProjectV2Item{id isArchived project{id} content{... on DraftIssue{title}}}}}',{'ids':ids})['nodes']
                for node in recorded:
                    if node and node['project']['id']==project_id and not node['isArchived'] and node.get('content') and node['content'].get('title'):
                        existing[node['content']['title']]=node['id']
    cards=[
      ('Playable world and restoration','done','Five seeded regions, five wardens, eight travelers, three regional currents and a persistent main ending. See the World and Progression Wiki page.'),
      ('Camp economy and exploration activities','done','143 items, 115 recipes, 41 building pieces, six crops, five regional fish, 30 discovery sites, 16 rotating requests, courier shipments and repeatable expeditions.'),
      ('Combat and original sprite animation','done','Player actions in four directions, 25 creature sheets, original equipment icons and 336 prepared animation frames. Native normal and quarter-speed review captures are retained.'),
      ('Saving and independent difficulty choices','done','Multiple journeys, automatic saving, three recoverable backup generations and Hardcore retirement markers. Five difficulties and three independent death rules.'),
      ('Five-language interface and player Wiki','done','642 keys per language: English, Simplified Chinese, Traditional Chinese, Spanish and Japanese. Regional fonts, native language-layout captures and an 11-page player Wiki.'),
      ('Original score and sound effects','done','Six original musical themes and 21 effects/ambience files, authored through note sequences and local synthesis. No commercial samples.'),
      ('Automated validation and Windows packaging','done' if validated else 'in progress','Run the five hosted CI checks, validate the freshly extracted package, and verify native exported screens in all five languages.'),
      ('Publish the release and protect main','done' if published and protected else 'in progress','Publish the complete Windows download and checksums, merge passing changes through a pull request, then verify the active ruleset with required checks, PRs, linear history and resolved discussions.'),
      ('Long-duration play sessions and balance','todo','Collect complete human session notes across difficulties and death rules. Measure progression pace, resource bottlenecks, combat recovery and meaningful choices before adding more catalog entries.'),
      ('Native-speaker translation review','todo','Review terminology, dialogue and every new item description in the four translated languages. Check the actual game layout after editorial changes.'),
      ('Controller and audio hardware matrix','todo','Record device models and exercise all menu flows, movement, aim, actions and hardware sound playback. Include speaker and headphone listening.'),
      ('Input remapping and additional accessibility settings','todo','Add remapping, UI scaling and contrast choices, then test complete control flows and five-language layouts.'),
      ('More regional discovery arrangements','todo','Add sites and traveler narratives that create new decisions and interactions; avoid increasing counts without meaningful play.'),
      ('Native Linux and macOS download validation','todo','Prepare platform builds only after native startup, play, saves and packaging checks on each target OS.')
    ]
    receipts=[]
    for title,state,body in cards:
        item_id=existing.get(title)
        if not item_id:
            item_id=graphql('mutation($project:ID!,$title:String!,$body:String!){addProjectV2DraftIssue(input:{projectId:$project,title:$title,body:$body}){projectItem{id}}}',{'project':project_id,'title':title,'body':body+'\n\n[Verification and limits]('+BASE+'/blob/main/docs/IMPLEMENTATION_STATUS.md)'})['addProjectV2DraftIssue']['projectItem']['id']
        graphql('mutation($project:ID!,$item:ID!,$field:ID!,$option:String!){updateProjectV2ItemFieldValue(input:{projectId:$project,itemId:$item,fieldId:$field,value:{singleSelectOptionId:$option}}){projectV2Item{id}}}',{'project':project_id,'item':item_id,'field':status['id'],'option':options[state]})
        receipts.append({'title':title,'id':item_id,'status':state})
    receipt={'url':project['url'],'id':project_id,'status_field':status['id'],'status_options':options,'public':True,'cards':receipts}
    (ROOT/'verification/project_publication.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'url':project['url'],'cards':len(receipts),'public':True},indent=2))

if __name__=='__main__':main()
