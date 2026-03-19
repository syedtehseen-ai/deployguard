def check_latest_tag(container):
    image = container.get("image", "")
    if ":latest" in image:
        return "Container uses latest tag"
    return None


def check_resources(container):
    resources = container.get("resources")
    if not resources:
        return "Missing resource limits/requests"
    return None


def check_security_context(container):
    sc = container.get("securityContext", {})
    if sc.get("runAsUser") == 0 or not sc:
        return "Container may run as root"
    return None

def check_probes(container):
    if "livenessProbe" not in container or "readinessProbe" not in container:
        return "Missing liveness/readiness probes"

def check_labels(parsed_yaml):
    metadata = parsed_yaml.get("metadata", {})
    if "labels" not in metadata:
        return "Missing labels in metadata"

def check_selector(parsed_yaml):
    try:
        labels = parsed_yaml["spec"]["template"]["metadata"]["labels"]
        selector = parsed_yaml["spec"]["selector"]["matchLabels"]

        if labels != selector:
            return "Selector does not match pod labels"
    except:
        return "Missing selector or labels"

def run_all_checks(parsed_yaml):
    issues = []

    try:
        containers = parsed_yaml["spec"]["template"]["spec"]["containers"]
    except KeyError:
        return ["Invalid Deployment structure"]

    # container-level checks
    for container in containers:
        for check in [
            check_latest_tag,
            check_resources,
            check_security_context,
            check_probes,
        ]:
            result = check(container)
            if result:
                issues.append(result)

    # deployment-level checks
    for check in [
        check_labels,
        check_selector,
    ]:
        result = check(parsed_yaml)
        if result:
            issues.append(result)

    return issues