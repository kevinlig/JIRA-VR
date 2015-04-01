using UnityEngine;
using LitJson;
using System;
using System.Collections;
using System.Collections.Generic	;



public class DataLoader : MonoBehaviour {

	public List<GameObject> inProgressCards;
	public List<GameObject> toDoCards;
	public List<GameObject> doneCards;
	public GameObject cardPrefab;

	// Use this for initialization
	void Start () {
		inProgressCards = new List<GameObject>();
		toDoCards = new List<GameObject>();
		doneCards = new List<GameObject>();
		StartCoroutine(DownloadJira());
	}

	// Update is called once per frame
	void Update () {

	}


	void ParseData(String data) {

			JsonData jsonData = JsonMapper.ToObject(data);

			// get issues
			for (int i = 0; i < jsonData["issues"].Count; i++) {

				String issueType = jsonData["issues"][i]["fields"]["status"]["name"].ToString();

				int currentSprint = 0;

				if (jsonData["issues"][i]["fields"]["customfield_10006"] != null) {
					for (int j = 0; j < jsonData["issues"][i]["fields"]["customfield_10006"].Count; j++) {
						String sprint = jsonData["issues"][i]["fields"]["customfield_10006"][j].ToString();

						if (sprint.IndexOf("state=ACTIVE") > -1) {
							currentSprint = 1;
						}
					}
				}

				if (currentSprint == 1) {

					GameObject newCard = (GameObject) Instantiate(cardPrefab);
					Issue cardIssue = newCard.GetComponent<Issue>();
					cardIssue.title = jsonData["issues"][i]["fields"]["summary"].ToString();
					cardIssue.assignee = jsonData["issues"][i]["fields"]["assignee"]["displayName"].ToString();
					cardIssue.photoUrl = jsonData["issues"][i]["fields"]["assignee"]["avatarUrls"]["48x48"].ToString();

					if (issueType == "In Progress") {
						inProgressCards.Add(newCard);
					}
					else if (issueType == "To Do") {
						toDoCards.Add(newCard);
					}
					else if (issueType == "Done") {
						doneCards.Add(newCard);
					}

				}
			}

			float toDoBottom = 0.11f;
			foreach (GameObject card in toDoCards) {

				card.transform.position = new Vector3(0.18f, toDoBottom, -8.2f);

				Issue thisIssue = card.GetComponent<Issue>();
				thisIssue.defaultPosition = new Vector3(0.18f, toDoBottom, -8.2f);

				toDoBottom += 0.45f;

			}

			float inProgressBottom = 0.11f;
			foreach (GameObject card in inProgressCards) {

				card.transform.position = new Vector3(2.78f, inProgressBottom, -8.2f);

				Issue thisIssue = card.GetComponent<Issue>();
				thisIssue.defaultPosition = new Vector3(2.78f, inProgressBottom, -8.2f);

				inProgressBottom += 0.45f;

			}



			float doneBottom = 0.11f;
			foreach (GameObject card in doneCards) {

				card.transform.position = new Vector3(5.46f, doneBottom, -8.2f);

				Issue thisIssue = card.GetComponent<Issue>();
				thisIssue.defaultPosition = new Vector3(5.46f, doneBottom, -8.2f);

				doneBottom += 0.45f;

			}

	}

	IEnumerator DownloadJira() {

		// authenticate
		Hashtable headers = new Hashtable();
		string url = "https://XXXXXXX.atlassian.net/rest/api/2/search?jql=project%3DXXXXXXXX%20AND%20updated%20%3E%3D%202015-03-30";

		// Add a custom header to the request.
		// In this case a basic authentication to access a password protected resource.
		headers["Authorization"] = "Basic XXXXXXXXXXXX";

		WWW jiraDownload = new WWW(url, null, headers);
		yield return jiraDownload;
	    if (jiraDownload.error == null)
	    {
	      //Sucessfully loaded the JSON string
	      ParseData(jiraDownload.text);
	    }
	    else
	    {
	      Debug.Log("ERROR: " + jiraDownload.error);
	    }



	}
}
