function init() {
  const dialog = document.getElementById("dialog");

  document.getElementById("show-dialog").addEventListener("click", () => {
    dialog.showModal();
  });

  document.getElementById("list-orgs").addEventListener("click", () => { listOrgs(); });
  document.getElementById("list-projects").addEventListener("click", () => { listProjects(); });

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


orgs = []

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
      orgs = []

      console.log(json)

      for (i in json.data) {
        org = json.data[i]
        orgs.push(org)
      }

      visualise()
    })

    .catch((error) => console.error("Fetch error:", error)); // In case of an error, it will be captured and logged.
}

projects = {}

function listProjects() {
  projects = {}

  for (i in orgs) {
    org = orgs[i]
    listProjectsInOrg(org.id)
  }
}

function listProjectsInOrg(orgName) {
  fetch("/tfc/organizations/" + orgName + "/projects", {
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

      projects[orgName] = []

      console.log(orgName)
      console.log(json)

      for (i in json.data) {
        project = json.data[i]
        projects[orgName].push(project)
      }

      visualise()
    })

    .catch((error) => console.error("Fetch error:", error)); // In case of an error, it will be captured and logged.
}

function visualise() {
  // Clear the visualisation
  visual = document.getElementById("visual")
  visual.innerHTML = ""

  for (i in orgs) {
    org = orgs[i]

    orgDiv = document.createElement('div');
    visual.append(orgDiv);

    orgDiv.classList.add('org')
    orgHeading = document.createElement('h1')
    orgHeading.appendChild(document.createTextNode(org.id))
    // TODO: make this a link to the org
    orgDiv.appendChild(orgHeading)



    for (j in projects[org.id]) {
      project = projects[org.id][j]

      projectDiv = document.createElement('div');
      orgDiv.append(projectDiv)

      projectDiv.classList.add('project')
      projectHeading = document.createElement('h1')
      projectHeading.appendChild(document.createTextNode(project.attributes.name))
      // TODO: make this a link to the project
      projectDiv.appendChild(projectHeading)


      // TODO: workspaces

      for (l = 0; l < 10; l++) {
        workspaceDiv = document.createElement('div');
        projectDiv.append(workspaceDiv)

        workspaceDiv.classList.add('workspace')

        // TODO: We probably want a few states here. I'm thinking at least: 
        if (Math.random() < 0.8) {
          workspaceDiv.classList.add('success')
        } else {
          workspaceDiv.classList.add('error')
        }
      }
    }


  }

}