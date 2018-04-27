---
title: "Announcing Asylo"
overview: A safe space for your apps and data, developed in the open.
publish_date: May 3, 2018
subtitle: Security in Plaintext
attribution: Nelly Porter and Serge Sim

order: 20

layout: blog
type: markdown
---
{% include home.html %}

When running sensitive workloads in the cloud, protection of data is the number
one consideration. You need to know you have control over your data and that the
confidentiality of that data is maintained. Google Cloud offers numerous data
protection controls by default, such as encryption of data in transit and at
rest. Today, we're excited to announce Asylo (Greek for "safe place"), an
open-source toolset that encrypts applications and data while they're in use.

Asylo offers isolation and protection of applications and data in cloud and
on-premise environments from security concerns including attackers, malicious
users, or compromised administrators. Traditionally, encryption in use has been
hard to do. Asylo makes it much easier by letting you easily build and package
your sensitive apps to run in an isolated, secure execution environment across
a variety of environments. We are building Asylo as an open source toolset so
that we can create the next generation of confidential computing together with
the community.

Asylo is a new kind of 'virtual' trusted execution environment that makes
confidential computing easy and gives you choices, so you're not locked in to a
particular hardware architecture or vendor.

provides confidentiality and integrity assurance for sensitive applications
running in "enclaves," in order to isolate and protect the data and execution of
applications.

Asylo offers much easier deployment and portability than alternative
approaches. It does this using:

*   **Containers.** To use Asylo, you package your application in a Docker
    container including any necessary build tools and dependencies.We supply a
    distributed Docker image that is agnostic to the backend an enclave uses,
    and includes all the dependencies you need to run your container anywhere,
    including supporting software or future enclave backends.
*  **Portability.** Support for a variety of backends. We designed Asylo to make
   it easy to create apps without having to refactor them to gain additional
   security properties. And, Asylo apps do not need to be aware of the
   intricacies of specific trusted execution implementations; you can port them
   with no code changes across different enclave backends. Those backends can
   range from your laptop, a workstation under your desk, a virtual machine in
   an on-premises server, or an instance in the cloud. Future backends based on
   Intel SGX or AMD SEV hardware will support the same rebuild and run
   portability.

Early adopters are already putting Asylo through its paces. Gemalto provides
digital security for a connected world and is using Asylo to secure its apps and
data.

"With the Asylo toolset, we can process data in a trusted and isolated
environment, which allows us to provide our customers with the most secure
products in the market. As a virtual offering, we can quickly create secure apps
using Asylo and give customers the deployment flexibility they need to meet
regulatory requirements." -XYZ, XYZ role at Gemalto

## The Asylo roadmap

It's still early days for Asylo, but we've come far enough to share our work
with the community at large.

In version 0.2, Asylo offers the necessary programming capabilities and tools to
help you develop portable enclaves. Further, it includes features and services
to help protect the data and apps in your enclaves, encrypting sensitive
communications and measuring the integrity of enclave code.

Coming soon, Asylo 0.3 release will allow you to use your existing apps--ust
reference or copy the app into the Asylo container, specify the backend,
rebuild, and run!

From there, where Asylo goes is largely up to you. We're looking forward too
seeing how you use and build on Asylo.

## Getting started with Asylo

It's easy to join companies like Gemlato and get started with Asylo--simply
download the Asylo toolchain and pre-built container image from Google Container
Registry. Be sure to check out the samples in the container, expand on them, or
use them as a guide when building your own Asylo apps from scratch.

Check out our quick-start guide [here]({{home}}/docs/guides/quickstart.html),
read the [documentation]({{home}}/docs) and join [our mailing
list](https://groups.google.com/forum/#!forum/asylo-users) to take part in the
discussion. We look forward to hearing from you on
[Github](https://github.com/google/asylo)!

