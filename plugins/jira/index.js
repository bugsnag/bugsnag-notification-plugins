var util = require("util");
var NotificationPlugin = require("../../notification-plugin.js")

function Jira() {

}
util.inherits(Jira, NotificationPlugin);

Jira.receiveEvent = function (config, event) {
  //Build the message
  if( event.error ){
    
  }

  //Build the request
  params = {
    fields: {
      project:{ 
        key: config.projectKey
      },
      summary: "",
      description: "",
      issuetype: {
        name: config.issueType
      }
    }
  }

  this.request
    .post(config.host + "/rest/api/2/issue")
    .send(params)
    .set('Content-Type', 'application/json')
    .set('Accept', 'application/json')
    .end(function(res){
      if (res.ok) {
        console.log('success', JSON.stringify(res.body));
      } else {
        console.log('error', res.text);
      }
    });
};

module.exports = Jira;