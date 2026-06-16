# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {}
# META }

# CELL ********************

# Welcome to your new notebook
# Type here in the cell editor to add code!


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import time
import requests

# ============================================
# CONFIG
# ============================================
TENANT_ID = "f49a8b5b-b823-476e-9774-2865e550dc1d"
CLIENT_ID = "e2ba1aaa-a00a-4b58-9776-cdba3dfd8aeb"
CLIENT_SECRET = "L8x8Q~pQSHw59iTlq6zRsLl._AD8K4KxUBIOocTd"
WORKSPACE_ID = "a554479c-4ad2-44ef-9fd5-cc10a60cba3d"

AUTH_URL = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"
FABRIC_SCOPE = "https://api.fabric.microsoft.com/.default"
BASE_URL = "https://api.fabric.microsoft.com/v1"


# ============================================
# AUTH
# ============================================
def get_access_token():
    payload = {
        "grant_type": "client_credentials",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "scope": FABRIC_SCOPE
    }

    response = requests.post(AUTH_URL, data=payload, timeout=60)
    response.raise_for_status()

    return response.json()["access_token"]


def get_headers(token):
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }


# ============================================
# GET CONNECTION
# ============================================
def get_git_connection(token, workspace_id):
    url = f"{BASE_URL}/workspaces/{workspace_id}/git/connection"
    headers = get_headers(token)

    response = requests.get(url, headers=headers, timeout=60)

    if response.status_code == 200:
        return response.json()

    if response.status_code == 404:
        return None

    response.raise_for_status()


# ============================================
# LRO POLLING
# ============================================
def poll_operation(token, operation_id, retry_after=5, max_wait_seconds=1800):
    url = f"{BASE_URL}/operations/{operation_id}"
    headers = get_headers(token)

    start_time = time.time()

    while True:
        response = requests.get(url, headers=headers, timeout=60)
        response.raise_for_status()

        payload = response.json()
        status = payload.get("status")

        print(f"Operation status: {status}")

        if status not in ("NotStarted", "Running"):
            return payload

        if time.time() - start_time > max_wait_seconds:
            raise TimeoutError("Operation polling timed out.")

        time.sleep(retry_after)


# ============================================
# GET STATUS
# ============================================
def get_git_status(token, workspace_id):
    url = f"{BASE_URL}/workspaces/{workspace_id}/git/status"
    headers = get_headers(token)

    response = requests.get(url, headers=headers, timeout=120)

    if response.status_code == 200:
        return response.json()

    if response.status_code == 202:
        operation_id = response.headers.get("x-ms-operation-id")
        retry_after = int(response.headers.get("Retry-After", "5"))

        if not operation_id:
            raise RuntimeError("202 received but x-ms-operation-id header is missing.")

        return poll_operation(token, operation_id, retry_after=retry_after)

    response.raise_for_status()


# ============================================
# MAIN
# ============================================
def main():
    print("Getting Fabric access token...")
    token = get_access_token()
    print("Access token acquired.")

    print("\nChecking Git connection...")
    connection = get_git_connection(token, WORKSPACE_ID)

    if not connection:
        print("Workspace is not connected to Git.")
        return

    print("Workspace is connected to Git.")
    print("Connection details:")
    print(connection)

    print("\nGetting Git status...")
    status = get_git_status(token, WORKSPACE_ID)

    print("Git status response:")
    print(status)


if __name__ == "__main__":
    main()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import time
import requests

# ============================================
# CONFIG
# ============================================
TENANT_ID = "f49a8b5b-b823-476e-9774-2865e550dc1d"
CLIENT_ID = "e2ba1aaa-a00a-4b58-9776-cdba3dfd8aeb"
CLIENT_SECRET = "L8x8Q~pQSHw59iTlq6zRsLl._AD8K4KxUBIOocTd"
WORKSPACE_ID = "a554479c-4ad2-44ef-9fd5-cc10a60cba3d"

AUTH_URL = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"
FABRIC_SCOPE = "https://api.fabric.microsoft.com/.default"
BASE_URL = "https://api.fabric.microsoft.com/v1"


# ============================================
# AUTH
# ============================================
def get_access_token():
    payload = {
        "grant_type": "client_credentials",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "scope": FABRIC_SCOPE
    }
    response = requests.post(AUTH_URL, data=payload, timeout=60)
    response.raise_for_status()
    return response.json()["access_token"]


def get_headers(token):
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }


# ============================================
# GET CONNECTION
# ============================================
def get_git_connection(token, workspace_id):
    url = f"{BASE_URL}/workspaces/{workspace_id}/git/connection"
    headers = get_headers(token)

    response = requests.get(url, headers=headers, timeout=60)

    if response.status_code == 200:
        return response.json()

    if response.status_code == 404:
        return None

    response.raise_for_status()


# ============================================
# MY GIT CREDENTIALS
# ============================================
def get_my_git_credentials(token, workspace_id):
    url = f"{BASE_URL}/workspaces/{workspace_id}/git/myGitCredentials"
    headers = get_headers(token)

    response = requests.get(url, headers=headers, timeout=60)
    response.raise_for_status()
    return response.json()


def update_my_git_credentials_to_configured_connection(token, workspace_id, connection_id):
    url = f"{BASE_URL}/workspaces/{workspace_id}/git/myGitCredentials"
    headers = get_headers(token)

    body = {
        "source": "ConfiguredConnection",
        "connectionId": connection_id
    }

    response = requests.patch(url, headers=headers, json=body, timeout=60)
    response.raise_for_status()

    if response.text:
        return response.json()
    return {"status": "updated"}


# ============================================
# LRO POLLING
# ============================================
def poll_operation(token, operation_id, retry_after=5, max_wait_seconds=1800):
    url = f"{BASE_URL}/operations/{operation_id}"
    headers = get_headers(token)

    start_time = time.time()

    while True:
        response = requests.get(url, headers=headers, timeout=60)
        response.raise_for_status()

        payload = response.json()
        status = payload.get("status")

        print(f"Operation status: {status}")

        if status not in ("NotStarted", "Running"):
            return payload

        if time.time() - start_time > max_wait_seconds:
            raise TimeoutError("Operation polling timed out.")

        time.sleep(retry_after)


# ============================================
# GET STATUS
# ============================================
def get_git_status(token, workspace_id):
    url = f"{BASE_URL}/workspaces/{workspace_id}/git/status"
    headers = get_headers(token)

    response = requests.get(url, headers=headers, timeout=120)

    if response.status_code == 200:
        return response.json()

    if response.status_code == 202:
        operation_id = response.headers.get("x-ms-operation-id")
        retry_after = int(response.headers.get("Retry-After", "5"))

        if not operation_id:
            raise RuntimeError("202 received but x-ms-operation-id header is missing.")

        return poll_operation(token, operation_id, retry_after=retry_after)

    # Surface the actual Fabric error payload if present
    try:
        error_payload = response.json()
    except Exception:
        error_payload = response.text

    raise RuntimeError(f"Get Status failed: {response.status_code} - {error_payload}")


# ============================================
# MAIN
# ============================================
def main():
    print("Getting Fabric access token...")
    token = get_access_token()
    print("Access token acquired.")

    print("\nChecking Git connection...")
    connection = get_git_connection(token, WORKSPACE_ID)

    if not connection:
        print("Workspace is not connected to Git.")
        return

    print("Workspace is connected to Git.")
    print("Connection details:")
    print(connection)

    print("\nGetting my Git credentials...")
    creds = get_my_git_credentials(token, WORKSPACE_ID)
    print("My Git credentials:")
    print(creds)

    source = creds.get("source")

    if source == "None":
        print("\nGit credentials are not configured for this caller.")
        provider_details = connection.get("gitProviderDetails", {})
        connection_id = provider_details.get("connectionId")

        if not connection_id:
            raise RuntimeError(
                "Workspace Git connection was found, but connectionId is missing from "
                "gitProviderDetails. Print the full connection payload and inspect it."
            )

        print(f"Updating my Git credentials to ConfiguredConnection using connectionId: {connection_id}")
        update_result = update_my_git_credentials_to_configured_connection(
            token,
            WORKSPACE_ID,
            connection_id
        )
        print("Update My Git Credentials result:")
        print(update_result)

        print("\nRe-checking my Git credentials...")
        creds = get_my_git_credentials(token, WORKSPACE_ID)
        print(creds)

    elif source == "ConfiguredConnection":
        print("\nGit credentials are already configured through a connection.")

    elif source == "Automatic":
        print("\nGit credentials are Automatic.")
        print("For GitHub + service principal, Automatic is not the path you want.")
    else:
        print(f"\nUnexpected credentials source: {source}")

    print("\nGetting Git status...")
    status = get_git_status(token, WORKSPACE_ID)
    print("Git status response:")
    print(status)


if __name__ == "__main__":
    main()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import time
import requests

# ============================================
# CONFIG
# ============================================
TENANT_ID = "f49a8b5b-b823-476e-9774-2865e550dc1d"
CLIENT_ID = "e2ba1aaa-a00a-4b58-9776-cdba3dfd8aeb"
CLIENT_SECRET = "L8x8Q~pQSHw59iTlq6zRsLl._AD8K4KxUBIOocTd"
WORKSPACE_ID = "A6D2C31B-0B03-4C60-A258-C2664C56FE3D"


AUTH_URL = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"
FABRIC_SCOPE = "https://api.fabric.microsoft.com/.default"
BASE_URL = "https://api.fabric.microsoft.com/v1"


# ============================================
# AUTH
# ============================================
def get_access_token():
    payload = {
        "grant_type": "client_credentials",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "scope": FABRIC_SCOPE
    }
    response = requests.post(AUTH_URL, data=payload, timeout=60)
    response.raise_for_status()
    return response.json()["access_token"]


def get_headers(token):
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }


# ============================================
# GIT CONNECTION
# ============================================
def get_git_connection(token, workspace_id):
    url = f"{BASE_URL}/workspaces/{workspace_id}/git/connection"
    response = requests.get(url, headers=get_headers(token), timeout=60)
    response.raise_for_status()
    return response.json()


# ============================================
# MY GIT CREDENTIALS
# ============================================
def get_my_git_credentials(token, workspace_id):
    url = f"{BASE_URL}/workspaces/{workspace_id}/git/myGitCredentials"
    response = requests.get(url, headers=get_headers(token), timeout=60)
    response.raise_for_status()
    return response.json()


def update_my_git_credentials_to_configured_connection(token, workspace_id, connection_id):
    url = f"{BASE_URL}/workspaces/{workspace_id}/git/myGitCredentials"
    body = {
        "source": "ConfiguredConnection",
        "connectionId": connection_id
    }
    response = requests.patch(url, headers=get_headers(token), json=body, timeout=60)
    response.raise_for_status()
    if response.text:
        return response.json()
    return {"status": "updated"}


# ============================================
# CONNECTIONS
# ============================================
def list_connections(token):
    headers = get_headers(token)
    url = f"{BASE_URL}/connections"
    all_connections = []

    while url:
        response = requests.get(url, headers=headers, timeout=60)
        response.raise_for_status()
        payload = response.json()

        all_connections.extend(payload.get("value", []))
        url = payload.get("continuationUri")

    return all_connections


def find_matching_github_connection(connections, git_connection_payload):
    provider = git_connection_payload.get("gitProviderDetails", {}) or {}

    target_owner = (provider.get("ownerName") or "").lower()
    target_repo = (provider.get("repositoryName") or "").lower()

    matches = []

    for c in connections:
        details = c.get("connectionDetails", {}) or {}
        display_name = (c.get("displayName") or "").lower()
        path = (details.get("path") or "").lower()
        conn_type = (details.get("type") or "").lower()

        score = 0

        if "github" in display_name:
            score += 1
        if "github" in path:
            score += 1
        if target_owner and target_owner in display_name:
            score += 2
        if target_owner and target_owner in path:
            score += 2
        if target_repo and target_repo in display_name:
            score += 2
        if target_repo and target_repo in path:
            score += 2
        if conn_type == "web" and "github" in path:
            score += 1

        if score > 0:
            matches.append((score, c))

    matches.sort(key=lambda x: x[0], reverse=True)

    if not matches:
        return None

    return matches[0][1]


# ============================================
# LRO POLLING
# ============================================
def poll_operation(token, operation_id, retry_after=5, max_wait_seconds=1800):
    url = f"{BASE_URL}/operations/{operation_id}"
    headers = get_headers(token)
    start_time = time.time()

    while True:
        response = requests.get(url, headers=headers, timeout=60)
        response.raise_for_status()

        payload = response.json()
        status = payload.get("status")
        print(f"Operation status: {status}")

        if status not in ("NotStarted", "Running"):
            return payload

        if time.time() - start_time > max_wait_seconds:
            raise TimeoutError("Operation polling timed out.")

        time.sleep(retry_after)


# ============================================
# GET STATUS
# ============================================
def get_git_status(token, workspace_id):
    url = f"{BASE_URL}/workspaces/{workspace_id}/git/status"
    headers = get_headers(token)

    response = requests.get(url, headers=headers, timeout=120)

    if response.status_code == 200:
        return response.json()

    if response.status_code == 202:
        operation_id = response.headers.get("x-ms-operation-id")
        retry_after = int(response.headers.get("Retry-After", "5"))

        if not operation_id:
            raise RuntimeError("202 received but x-ms-operation-id header is missing.")

        return poll_operation(token, operation_id, retry_after=retry_after)

    try:
        error_payload = response.json()
    except Exception:
        error_payload = response.text

    raise RuntimeError(f"Get Status failed: {response.status_code} - {error_payload}")


# ============================================
# MAIN
# ============================================
def main():
    print("Getting Fabric access token...")
    token = get_access_token()
    print("Access token acquired.")

    print("\nGetting workspace Git connection...")
    git_connection = get_git_connection(token, WORKSPACE_ID)
    print(git_connection)

    print("\nGetting my Git credentials...")
    creds = get_my_git_credentials(token, WORKSPACE_ID)
    print(creds)

    if creds.get("source") == "None":
        print("\nListing Fabric connections...")
        connections = list_connections(token)
        print(f"Found {len(connections)} connections.")

        print("\nFinding matching GitHub connection...")
        matched = find_matching_github_connection(connections, git_connection)

        if not matched:
            raise RuntimeError("No matching GitHub Fabric connection was found.")

        print("Matched connection:")
        print(matched)

        connection_id = matched["id"]

        print(f"\nUpdating my Git credentials using connectionId: {connection_id}")
        result = update_my_git_credentials_to_configured_connection(token, WORKSPACE_ID, connection_id)
        print(result)

        print("\nRe-checking my Git credentials...")
        creds = get_my_git_credentials(token, WORKSPACE_ID)
        print(creds)

    print("\nGetting Git status...")
    status = get_git_status(token, WORKSPACE_ID)
    print(status)


if __name__ == "__main__":
    main()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

import time
import json
import base64
import requests
from typing import Any, Dict, List, Optional

TENANT_ID = "f49a8b5b-b823-476e-9774-2865e550dc1d"
CLIENT_ID = "e2ba1aaa-a00a-4b58-9776-cdba3dfd8aeb"
CLIENT_SECRET = "L8x8Q~pQSHw59iTlq6zRsLl._AD8K4KxUBIOocTd"
WORKSPACE_ID = "A6D2C31B-0B03-4C60-A258-C2664C56FE3D"


AUTH_URL = f"https://login.microsoftonline.com/{TENANT_ID}/oauth2/v2.0/token"
FABRIC_SCOPE = "https://api.fabric.microsoft.com/.default"
BASE_URL = "https://api.fabric.microsoft.com/v1"

OUTPUT_JSON = "fabric_workspace_metadata.json"


def get_access_token() -> str:
    payload = {
        "grant_type": "client_credentials",
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
        "scope": FABRIC_SCOPE
    }
    response = requests.post(AUTH_URL, data=payload, timeout=60)
    response.raise_for_status()
    return response.json()["access_token"]


def get_headers(token: str) -> Dict[str, str]:
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }


def poll_operation(token: str, operation_id: str, retry_after: int = 5, max_wait_seconds: int = 1800) -> Dict[str, Any]:
    url = f"{BASE_URL}/operations/{operation_id}"
    headers = get_headers(token)
    start_time = time.time()

    while True:
        response = requests.get(url, headers=headers, timeout=60)
        response.raise_for_status()
        payload = response.json()
        status = payload.get("status")

        if status not in ("NotStarted", "Running"):
            return payload

        if time.time() - start_time > max_wait_seconds:
            raise TimeoutError(f"Operation {operation_id} timed out.")

        time.sleep(retry_after)


def list_all_items(token: str, workspace_id: str) -> List[Dict[str, Any]]:
    headers = get_headers(token)
    url = f"{BASE_URL}/workspaces/{workspace_id}/items?recursive=true&include=DefaultIdentity"
    items: List[Dict[str, Any]] = []

    while url:
        response = requests.get(url, headers=headers, timeout=60)
        response.raise_for_status()
        payload = response.json()

        items.extend(payload.get("value", []))
        url = payload.get("continuationUri")

    return items


def list_item_connections(token: str, workspace_id: str, item_id: str) -> Dict[str, Any]:
    headers = get_headers(token)
    url = f"{BASE_URL}/workspaces/{workspace_id}/items/{item_id}/connections"
    results: List[Dict[str, Any]] = []

    while url:
        response = requests.get(url, headers=headers, timeout=60)
        if response.status_code == 403:
            return {"error": "Forbidden", "status_code": 403}
        if response.status_code == 404:
            return {"error": "NotFound", "status_code": 404}

        response.raise_for_status()
        payload = response.json()
        results.extend(payload.get("value", []))
        url = payload.get("continuationUri")

    return {"value": results}


def decode_definition_parts(parts: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    decoded_parts = []

    for part in parts:
        path = part.get("path")
        payload = part.get("payload")
        payload_type = part.get("payloadType")

        decoded_payload_text = None
        decoded_payload_json = None

        if payload_type == "InlineBase64" and payload:
            try:
                raw = base64.b64decode(payload)
                decoded_payload_text = raw.decode("utf-8", errors="replace")
                try:
                    decoded_payload_json = json.loads(decoded_payload_text)
                except Exception:
                    decoded_payload_json = None
            except Exception as ex:
                decoded_payload_text = f"<<base64 decode failed: {str(ex)}>>"

        decoded_parts.append({
            "path": path,
            "payloadType": payload_type,
            "payloadText": decoded_payload_text,
            "payloadJson": decoded_payload_json
        })

    return decoded_parts


def get_item_definition(token: str, workspace_id: str, item_id: str) -> Dict[str, Any]:
    headers = get_headers(token)
    url = f"{BASE_URL}/workspaces/{workspace_id}/items/{item_id}/getDefinition"

    response = requests.post(url, headers=headers, timeout=60)

    if response.status_code == 403:
        return {"error": "Forbidden", "status_code": 403}
    if response.status_code == 404:
        return {"error": "NotFound", "status_code": 404}

    if response.status_code == 202:
        operation_id = response.headers.get("x-ms-operation-id")
        retry_after = int(response.headers.get("Retry-After", "5"))

        if not operation_id:
            return {"error": "LRO started but operation id missing", "status_code": 202}

        final_payload = poll_operation(token, operation_id, retry_after=retry_after)

        result = final_payload.get("result", {})
        parts = result.get("definition", {}).get("parts", [])
        return {
            "raw": final_payload,
            "definitionPartsDecoded": decode_definition_parts(parts),
            "definitionPartCount": len(parts)
        }

    response.raise_for_status()
    payload = response.json()
    parts = payload.get("definition", {}).get("parts", [])
    return {
        "raw": payload,
        "definitionPartsDecoded": decode_definition_parts(parts),
        "definitionPartCount": len(parts)
    }


def summarize_definition(definition_result: Dict[str, Any]) -> Dict[str, Any]:
    if "error" in definition_result:
        return definition_result

    parts = definition_result.get("definitionPartsDecoded", [])
    paths = [p.get("path") for p in parts if p.get("path")]

    return {
        "definitionPartCount": definition_result.get("definitionPartCount", 0),
        "definitionPaths": paths
    }


SKIP_ITEM_TYPES = {"SQLEndpoint", "Lakehouse", "Warehouse"}

def build_workspace_metadata_inventory(token: str, workspace_id: str) -> Dict[str, Any]:
    items = list_all_items(token, workspace_id)

    output: Dict[str, Any] = {
        "workspaceId": workspace_id,
        "itemCount": len(items),
        "items": []
    }

    for index, item in enumerate(items, start=1):
        item_id = item.get("id")
        item_type = item.get("type")
        display_name = item.get("displayName")

        print(f"[{index}/{len(items)}] Processing {item_type}: {display_name}")

        if item_type in SKIP_ITEM_TYPES:
            print(f"Skipping {item_type}: {display_name}")

            output["items"].append({
                "id": item_id,
                "displayName": display_name,
                "description": item.get("description"),
                "type": item_type,
                "workspaceId": item.get("workspaceId"),
                "folderId": item.get("folderId"),
                "defaultIdentity": item.get("defaultIdentity"),
                "connections": None,
                "definitionSummary": {"skipped": True, "reason": f"{item_type} skipped"},
                "definitionRaw": None
            })
            continue

        item_connections = list_item_connections(token, workspace_id, item_id)

        definition_result = get_item_definition(token, workspace_id, item_id)
        definition_summary = summarize_definition(definition_result)

        output["items"].append({
            "id": item_id,
            "displayName": display_name,
            "description": item.get("description"),
            "type": item_type,
            "workspaceId": item.get("workspaceId"),
            "folderId": item.get("folderId"),
            "defaultIdentity": item.get("defaultIdentity"),
            "connections": item_connections,
            "definitionSummary": definition_summary,
            "definitionRaw": definition_result.get("raw") if "raw" in definition_result else definition_result
        })

    return output


def main():
    token = get_access_token()
    metadata = build_workspace_metadata_inventory(token, WORKSPACE_ID)

    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2, ensure_ascii=False)

    print(f"Saved metadata inventory to {OUTPUT_JSON}")
    print(f"Total items: {metadata['itemCount']}")


if __name__ == "__main__":
    main()

# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
