# Kubernetes Auth and Access Control

Notes from [Kubernetes Auth and Access Control by Eric Chiang](https://www.youtube.com/watch?v=WvnXemaYQ50)

On kubernetes, almost everything needs to talk to API Server, and it needs to authenticate and authorize its clients.

When a request comes in the API Server, two main steps happen:

1. Authentication: It parses the credentials and determines who’s talking to it.
2. Authorization: It determines if the client have the permissions to perform the action.

## Authentication

### Normal Users

Kubernetes users are not what you think they are! Our definition of users (a programmer that connects to the API service
using kubectl) is not a part of kubernetes API. Kubernetes calls these type of users normal users, and assumes that
they’re managed by an outside service.

For normal users, kubernetes **does not** have an object representing normal user accounts, it does not store things like
their credentials, and it only cares about their string representation (username and group names).

Kubernetes supports multiple authentication strategies that allow it to extract these representations from a request:

- client certificates (X509 certificates)
- HTTP basic authentication (static password files)
- Bearer token (static token files, bootstrap tokens)
- Authentication proxy
- etc.

When multiple authenticator modules are enabled, the first module to successfully authenticate the request short-circuits
evaluation. The API server does not guarantee the order authenticators run in.

Following are some of the most used authentication mechanisms:

#### X509 Client Certs

One of the most common methods for authentication. Admin of the cluster creates a Certificate Authority for the cluster.
When a client certificate is presented to the API server, it verifies it using the CA and extracts username and groups
of the request from “CN” (common name) and “O” (organization) fields of the certificate.

#### Static Token Files

A file containing a list of predefined tokens along with their corresponding username and groups. API Server simply checks
for the existence of the token and reads username/group information from its corresponding row. Mostly used for
bootstrapping the cluster.

The request’s header should contains `Authorization: Bearer <token>`

#### Bootstrap Tokens

A dynamically-managed Bearer token type stored as Secrets in the kube-system namespace, where they can be dynamically
managed and created.

The request’s header should contains `Authorization: Bearer <token>`

#### Static Password Files

A file containing a list of predefined usernames and passwords.

The request’s header should contains `Authorization: Bearer <token>`

#### OpenID Connect Tokens

In this mode API Server outsources the authentication process to a third party identity provider supporting OpenID Connect.
OpenID Connect is an extension of OAuth2 that defines some identity related fields (such as email) in its JWT (ID Token).

The request’s header should contains `Authorization: Bearer <JWT>`

#### Webhook Token Authentication

Webhook authentication is a hook for verifying bearer tokens. When a client attempts to authenticate with the API server
using a bearer token, the authentication webhook POSTs a JSON-serialized TokenReview object containing the token to the
remote service.

#### Authenticating Proxy

The API server can be configured to identify users from request header values, such as X-Remote-User. It is designed for
use in combination with an authenticating proxy, which sets the request header value.

#### Anonymous request

When enabled, requests that are not rejected by other configured authentication methods are treated as anonymous requests,
and given a username of system:anonymous and a group of system:unauthenticated.

From Kubernetes 1.6, anonymous access is enabled by default if an authorization mode other than AlwaysAllow is used.

### Service Accounts

Service accounts are a category of users that Kubernetes manages. They’re basically bearer tokens managed by kubernetes,
and they’re the only type of bearer tokens/users that can be accessed and managed through Kubernetes API.

Service accounts are usually created automatically by the API server and associated with pods running in the cluster through
the ServiceAccount Admission Controller. Bearer tokens are mounted into pods at well-known locations, and allow in-cluster
processes to talk to the API server.

If you create a service account using kubectl, you’ll get back a service account object that contains a list of secrets,
one of these secrets is a JWT signed by the API server, called Service Account Token. This JWT is what allows Pods to
talk with the API server.

Service Accounts are what gives Pods inside a cluster identity. A Pod’s service account secrets will be mounted into the
Pod in a predefined location, which can be configured in Pod definition. Keep in mind that anyone that can read your service
account secrets can act as behalf of that Pod, so be careful what permissions you give to service accounts. Always keep
the principle of least privilege in mind.

## Authorization

API Server evaluates all of the request attributes against all policies and allows or denies the request. All parts of
an API request must be allowed by some policy in order to proceed. This means that permissions are **denied by default**.

Authorization takes usernames and group names and tries to decide if the request should be accepted or denied. Kubernetes
API server supports multiple authorization modes, and we can activate as many of them as we see fit.

### Node

A special-purpose authorization mode that grants permissions to kubelets based on the pods they are scheduled to run.

### Webhook

An authorization mode which causes Kubernetes to query an outside REST service when determining user privileges.

### Attribute-based access control (ABAC)

An access control paradigm whereby access rights are granted to users through the use of policies which combine attributes
together. The policies can use any type of attributes, e.g. user attributes, resource attributes, object, environment
attributes, etc.

### Role-based access control (RBAC)

A method of regulating access to computer or network resources based on the roles of individual users within an enterprise.

RBAC rules contain a subject (user/group), a verb (action), a resource, and optionally a namespace: e.g. User **A** can **create
Pods** in namespace **B**. You cannot refer to single objects or refer to fields in a resource, but you can refer to subresources
(e.g. nodes & status).

RBAC defines four top level objects: *Role*, *RoleBinding*, *ClusterRole*, and *ClusterRoleBinding*.

Roles, and ClusterRoles, are a set of powers or rules, e.g. “can create Pods and can edit Pods status”, and bindings allow
users or groups to have those powers.

Roles define rules in a particular namespace and ClusterRoles define rules on the entire cluster.

*ClusterRoleBindings* grant users/groups power throughout the entire cluster, and *RoleBindings* grant powers inside a
namespace. As a result *ClusterRoleBindings* can only refer to *ClusterRoles* but *RoleBindings* can either refer to a *Role*
(in the same namespace) or a *ClusterRole* (but reduce its powers to the namespace).

RBAC have built in access escalation prevention, you can’t give someone else an access that you don’t have. For bootstrapping
you either can disable this by a flag in API server, use API server’s insecure port, or use default roles and role bindings.

Default roles and role bindings give the admin to min a X509 certificate for “cluster-admin” and do the bootstrapping using
it.

## Dex

[Dex](https://github.com/dexidp/dex) is an OCID server that can be used as Kubernetes authentication plugin.
It federates login by going through other identity providers, e.g. Google, Github, OpenLDAP, etc. It can pull groups from
these identity providers and map them to your clusters groups defined by your role bindings.
