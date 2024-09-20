function init() {
  const dialog = document.getElementById("dialog");

  document.getElementById("show-dialog").addEventListener("click", () => {
    dialog.showModal();
  });

  document.getElementById("list-orgs").addEventListener("click", () => {
    listOrgs();
  });

  document.getElementById("api-token").value = localStorage.getItem("TFE_TOKEN");

  if (getAPIToken() == "") {
    dialog.showModal()
  }
}

// TODO: Save API token to long-term memory, on update
// https://www.w3schools.com/jsref/prop_win_localstorage.asp
//
// For now...
// localStorage.setItem("TFE_TOKEN", "FOO")

function getAPIToken() {
  return document.getElementById("api-token").value
}

function listOrgs() {
  // https://www.freecodecamp.org/news/how-to-send-http-requests-using-javascript/

  fetch("/tfc/organizations", {
    headers: {
      "Content-Type": "application/vnd.api+json",
      "Authorization": "Bearer " + getAPIToken(),
    },
  })
    .then((response) => {
      // If the response is not 2xx, throw an error
      if (!response.ok) {
        console.error("Network response was not ok")
        throw new Error("Network response was not ok");
      }

      return response.json()
    })
    .then(json => {
      // TODO: store this internally


      response = document.getElementById("response")
      response.innerHTML = JSON.stringify(json, null, 2);


      // Clear the visualisation
      visual = document.getElementById("visual")
      visual.innerHTML = ""

      for (i in json.data) {
        org = json.data[i]
        console.log(org)

        orgDiv = document.createElement('div');
        orgDiv.classList.add('org')
        orgDiv.appendChild(document.createTextNode(org.id))
        visual.append(orgDiv)

      }


    })

    .catch((error) => console.error("Fetch error:", error)); // In case of an error, it will be captured and logged.
}
