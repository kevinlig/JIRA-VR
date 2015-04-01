using UnityEngine;
using System;
using System.Collections;

public class Issue : MonoBehaviour {

	public String title;
	public String assignee;

	public String photoUrl;

	public TextMesh titleMesh;
	public TextMesh assignMesh;

	public GameObject photoObject;


	public Vector3 defaultPosition;


	void Start() {

		foreach (Transform t in transform) {
			if (t.name == "title") {
				titleMesh = t.gameObject.GetComponentInChildren<TextMesh>();
			}
			else if (t.name == "assign") {
				assignMesh = t.gameObject.GetComponentInChildren<TextMesh>();
			}
			else if (t.name == "Photo") {
				photoObject = t.gameObject;
			}
		}

		// format the text
		titleMesh.text = title;
    TextSize ts = new TextSize(titleMesh);
    ts.FitToWidth(0.5f);


		assignMesh.text = assignee;
		TextSize ats = new TextSize(assignMesh);
		ats.FitToWidth(0.5f);

		StartCoroutine(DownloadPhoto());




	}

	 void Update() {

	}


	IEnumerator DownloadPhoto() {
		Hashtable headers = new Hashtable();
		headers["Authorization"] = "Basic XXXXXXXXXX";
		WWW www = new WWW(photoUrl, null, headers);
		yield return www;
		photoObject.renderer.material.mainTexture = www.texture;
	}

}
