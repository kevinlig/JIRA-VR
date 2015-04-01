using UnityEngine;
using System;
using System.Collections;
using System.Collections.Generic;


public class GameController : MonoBehaviour {

	public GameObject pinPointer;
	public int currentMode = 0;
	public int currentStack = 0;
	public int currentCard = 0;

	public GameObject currentCardObj;

	public DataLoader dataLoader;

	float lastTime = 0;

	// Use this for initialization
	void Start () {

	}

	// Update is called once per frame
	void Update () {

	}

	void FixedUpdate() {
		// check player prefs
		if (PlayerPrefs.HasKey("direction")) {
			if (PlayerPrefs.GetString("direction") != "statusquo" && Time.timeSinceLevelLoad - lastTime >= 1.5f) {
				PlayerMoved(PlayerPrefs.GetString("direction"));
			}
		}


		if (Time.timeSinceLevelLoad - lastTime >= 1.5f) {
			if (Input.GetKeyDown(KeyCode.Q)) {
				PlayerMoved("left");
			}
			if (Input.GetKeyDown(KeyCode.E)) {
				PlayerMoved("right");
			}
			if (Input.GetKeyDown(KeyCode.W)) {
				PlayerMoved("up");
			}
		}
	}

	void PlayerMoved(String direction) {

		if (currentMode == 0) {
			MoveStack(direction);
		}
		else {
			MoveCard(direction);
		}

		lastTime = Time.timeSinceLevelLoad;

		PlayerPrefs.SetString("direction", "statusquo");
		PlayerPrefs.Save();
	}

	void MoveStack(String direction) {

		if (direction == "left") {
			if (currentStack > 0) {
				currentStack = currentStack - 1;
			}

			MovePinToStack(currentStack);
		}

		else if (direction == "right") {
			if (currentStack < 2) {
				currentStack = currentStack + 1;
			}
			MovePinToStack(currentStack);
		}



		else if (direction == "up") {
			// show cards
			currentMode = 1;
			currentCard = 0;
			DisplayCardInStack(currentStack, 0);
		}



	}

	void MoveCard(string direction) {

		if (direction == "left") {
			if (currentCard > 0) {
				currentCard = currentCard - 1;
				DisplayCardInStack(currentStack, currentCard);

			}
			else {
				currentMode = 0;
				currentCard = 0;
				if (currentCardObj != null) {
					RemoveCardFromStack(currentCardObj);
				}
			}
		}
		else if (direction == "right") {

			List<GameObject> stack;
			if (currentStack == 0) {
				stack = dataLoader.toDoCards;
			}
			else if (currentStack == 1) {
				stack = dataLoader.inProgressCards;
			}
			else {
				stack = dataLoader.doneCards;
			}

			if (currentCard < stack.Count - 1) {
				currentCard = currentCard + 1;
				DisplayCardInStack(currentStack, currentCard);

			}
			else {
				currentMode = 0;
				currentCard = 0;
				if (currentCardObj != null) {
					RemoveCardFromStack(currentCardObj);
				}
			}
		}

	}

	void MovePinToStack(int stackNumber) {
		Vector3 destination;
		if (stackNumber == 0) {
			destination = new Vector3(0.28f, 0.0f, -9.15f);

		}
		else if (stackNumber == 1) {
			destination = new Vector3(2.72f, 0.0f, -9.15f);
		}
		else {
			destination = new Vector3(5.3f, 0.0f, -9.15f);
		}

		Hashtable args = new Hashtable();
		args.Add("easetype", "easeOutQuad");
		args.Add("position", destination);
		args.Add("time", 1.0f);
		iTween.MoveTo(pinPointer, args);
	}


	void DisplayCardInStack(int stackNumber, int cardNumber) {

		List<GameObject> stack;
		if (stackNumber == 0) {
			stack = dataLoader.toDoCards;
		}
		else if (stackNumber == 1) {
			stack = dataLoader.inProgressCards;
		}
		else {
			stack = dataLoader.doneCards;
		}

		if (stack.Count == 0) {
			// no cards
			return;
		}

		if (currentCardObj != null) {
			RemoveCardFromStack(currentCardObj);
		}

		GameObject card = stack[stack.Count - cardNumber - 1];

		currentCardObj = card;

		Hashtable args = new Hashtable();
		args.Add("easetype", "easeOutQuad");
		args.Add("position", new Vector3(2.557f, 0.614f, -9.283f));
		args.Add("time", 0.7f);
		args.Add("oncomplete","RotateCardToDisplay");
		args.Add("oncompletetarget",gameObject);
		iTween.MoveTo(card, args);



	}

	public void RotateCardToDisplay() {

		Hashtable args = new Hashtable();
		args.Add("easetype", "easeOutQuad");
		args.Add("rotation", new Vector3(180.0f, 0, 0));
		args.Add("time", 0.5f);
		iTween.RotateTo(currentCardObj, args);

	}


	void RemoveCardFromStack(GameObject card) {

		Issue cardIssue = card.GetComponent<Issue>();

		Hashtable args = new Hashtable();
		args.Add("easetype", "easeOutQuad");
		args.Add("position", cardIssue.defaultPosition);
		args.Add("time", 0.7f);
		iTween.MoveTo(card, args);

		Hashtable args2 = new Hashtable();
		args2.Add("easetype", "easeOutQuad");
		args2.Add("rotation", new Vector3(270.0f, 0, 0));
		args2.Add("time", 0.5f);
		iTween.RotateTo(card, args2);

	}
}
