---
title: Asylo Quickstart Guide
overview: Install Asylo, build, and run your first enclave! 

order: 10

layout: docs
type: markdown
toc: false
---
{% include home.html %}

This guide demonstrates using Asylo to protect secret data from an attacker
with root privileges.

## Introduction

### What is an enclave?

We generally assume the kernel has privileged access to hardware, and if an
attacker can execute code as root then every secret on the machine is lost. For
instance, if an attacker gets root on a machine managing TLS keys, we assume
those keys are lost.

Enclaves are an emerging technology that changes this assumption. An enclave is
a special execution context where code can run safe from a malicious kernel,
with the guarantee that even root can not extract its secrets or compromise its
integrity. This is enabled by isolation technologies in hardware, for instance
VMX or SGX from Intel or TrustZone from ARM. The technologies enable new forms
of privilege isolation beyond the usual kernel/user-space separation.

### What is Asylo?

Security features in hardware are exciting for developers building secure
applications, but in practice there's a big gap between having a raw capability
and application development. Building useful applications requires tools to
construct, load, and consume enclaves. Doing useful work in an enclave requires
programming language support and access to core platform libraries.

Asylo is Google's abstract enclave model and software development platform
for enclave applications. It is intended for use by internal Google developers,
third-party partners, and GCP customers. The Asylo project aims to provide a
software development platform supporting a broad range of internal and customer
use cases. Asylo is a complete development platform for building complex
applications and not just an API layer. In a sense, an enclave runs on a
special-purpose embedded computer inside a conventional machine, and Asylo is
its operating system and runtime library.

This guide demonstrates a simple example enclave. In this example, we
demonstrate initializing an enclave, passing arguments to code running inside
it, and returning the processed results. This demonstrates the basic
functionality Asylo provides and the steps required to get up and running.

## Where to find the example code

The code for this guide is in our examples directory
google3/third_party/asylo/examples/quickstart.

## Overall Approach

Asylo takes an object-oriented approach to enclave development. Conceptually,
an enclave is a collection of private data and private logic, along with public
methods to access it. This concept is modeled in C++ as an object; to implement
an enclave application, developers create a subclass inheriting from an abstract
TrustedApplication class and implement its methods.

## Message passing interface

Every enclave provides a limited number of entry points where trusted execution
may begin or resume. We refer to the process of switching from an untrusted
execution environment to a trusted environment as _entering_ an enclave.

On the untrusted side, the Asylo API defines enclave entry points where
messages can be passed into the enclave:

-   `EnterAndInitialize` takes an `EnclaveConfig`, which contains basic enclave
    configuration settings, and passes it to the enclave.
-   `EnterAndRun` takes a customized `EnclaveInput` for general purpose message
    passing, copies it into enclave, and populates an `EnclaveOutput` result.
    This method may be called an arbitrary number of times with different inputs
    after the enclave is initialized.
-   `EnterAndFinalize` passes an `EnclaveFinal` to the enclave, and destroys the
    enclave.

Each entry point takes a protocol buffer input and populates a protocol buffer
result. To implement an enclave application, the developer defines a class
inheriting from `TrustedApplication` and implements the logic to host in the
enclave. The `TrustedApplication` interface declares methods corresponding to
each entry point defined by the Asylo API:

-   `Initialize` takes `EnclaveConfig` from `EnterAndInitialize`, and
    initializes the enclave with the basic settings in `EnclaveConfig`. This
    method has a default implementation.
-   `Run` takes `EnclaveInput` from `EnterAndRun`, populates an `EnclaveOutput`
    result, and performs trusted execution. This method must be implemented by
    client code.
-   `Finalize` takes `EnclaveFinal` from `EnterAndFinalize`, and destroys the
    enclave. This method has a default implementation.

## Enclave life cycle

Entering an enclave is analogous to making a system call. The enclave entry
implements a gateway to privileged code with access to the enclave's resources.
Arguments are copied into the enclave's protected memory on entry and results
are copied out on exit.

```
int main(int argc, char *argv[]) {
  google::ParseCommandLineFlags(&argc, &argv, /*remove_flags=*/ true);

  // Part 1: Initialization

  asylo::EnclaveManager::Configure(asylo::EnclaveManagerOptions());
  auto manager_result = asylo::EnclaveManager::Instance();
  if (!manager_result.ok()) {
    LOG(QFATAL) << manager_result.status();
  }
  asylo::EnclaveManager *manager = manager_result.ValueOrDie();
  asylo::SimLoader loader(FLAGS_enclave_path, /*debug=*/true);
  asylo::Status status = manager->LoadEnclave("demo_enclave", loader);
  if (!status.ok()) {
    LOG(QFATAL) << status;
  }

  // Part 2: Secure execution

  asylo::EnclaveClient *client = manager->GetClient("demo_enclave");
  asylo::EnclaveInput input;
  const string user_message = GetUserString();
  SetEnclaveUserMessage(&input, user_message);
  status = client->EnterAndRun(input, /*output=*/nullptr);
  if (!status.ok()) {
    LOG(QFATAL) << status;
  }

  // Part 3: Finalization

  asylo::EnclaveFinal final_input;
  status = manager->DestroyEnclave(client, final_input);
  if (!status.ok()) {
    LOG(QFATAL) << status;
  }

  return 0;
}
```

The three enclave entry points are shown in the above code. Let's go through
each part of the `main()` procedure.

### Part 1: Initialization

First, we configure a `SimLoader` object to fetch the enclave image from disk.
Next, we pass the loader and a configuration object to the `LoadEnclave` method
of the EnclaveManager singleton, which invokes the loader and binds the loaded
enclave to the name `"/demo_enclave"`.

### Part 2: Secure execution

Next, we fetch a handle to our enclave from the enclave manager and invoke the
enclave by calling `EnterAndRun`. `EnterAndRun` is the primary entry point used
to dispatch messages to the enclave. This method can be called an arbitrary
number of times. The `EnclaveInput` type can be extended by the user to provide
arbitrary input data to the enclave. In this example, we pass a string read from
stdin as input to the enclave. Similarly, `EnclaveOutput` can be user-extended
to provide arbitrary output values from the enclave.

### Part 3: Finalization

Finally, our sample main function calls `DestroyEnclave` to finalize and
terminate the enclave.

## Writing an enclave application

We just saw how to initialize, run, and finalize an enclave using the Asylo
SDK. These calls happened on the untrusted side of the enclave boundary. Now,
let's take a look at the code on the trusted side.

```
class EnclaveDemo : public TrustedApplication {
 public:
  EnclaveDemo() = default;

  Status Run(const EnclaveInput &input, EnclaveOutput *output) {
    string user_message = GetEnclaveUserMessage(input);
    string encrypt_message = EncryptMessage(user_message);
    std::cout << "Encrypted message:" << std::endl
              << encrypt_message << std::endl;
    return Status::OkStatus();
  }

  const string GetEnclaveUserMessage(const EnclaveInput &input) {
    return input.GetExtension(guide::asylo::enclave_input_demo).value();
  }

  void SetEnclaveOutputMessage(EnclaveOutput *enclave_output,
                               const string &output_message) {
    guide::genclave::Demo *output = enclave_output->MutableExtension(
        guide::genclave::enclave_output_demo);
    output->set_value(output_message);
  }
};
```

Here, we define a class `EnclaveDemo`, which derives from `TrustedApplication`,
and implements our enclave's secure execution logic in its `Run` method. Its
`Run` method encrypts the input message and prints the resulting ciphertext.

At a minimum, an enclave author should implement the `Run` method in their
`TrustedApplication` to provide the core logic for their enclave (as in this
example). An enclave developer may also override `Initialize` and `Finalize` and
provide custom initialization and finalization logic for their enclave
application.

## Building an enclave application

Asylo implements an enclave backend for a simulator-based environment. To
build our enclave application, we define several targets that utilize this
backend.

```
genclave_proto_library(
    name = "demo_proto",
    srcs = ["demo.proto"],
    deps = ["//third_party/genclave:enclave_proto"],
)

sgx_enclave(
    name = "demo_enclave",
    srcs = ["demo_enclave.cc"],
    deps = [
        ":demo_proto_cc",
        "//third_party/genclave:enclave_runtime",
    ],
)

debug_enclave_driver(
    name = "demo",
    srcs = ["demo_driver.cc"],
    enclaves = [":demo_enclave"],
    deps = [
        ":demo_proto_cc",
        "//third_party/genclave:enclave_client",
        "//third_party/genclave/google_specific:flags",
        "//third_party/genclave/google_specific:logging",
    ],
)
```

The BUILD file shown above defines our enclave's logic in an `sgx_enclave`
called `:demo_enclave`. This target contains our implementation of
`TrustedApplication` and is linked against the Asylo runtime. We use an
`sgx_enclave` rule to generate a signed enclave that can be run in
non-simulation mode.

The untrusted component is the target `:demo_driver`, which contains code to
handle the logic of initializing, running, and finalizing the enclave, as well
as sending and receiving messages through the enclave boundary. Typically we
would write `demo` as a `cc_binary` target, but the `debug_enclave_driver` rule
makes life simpler to combine the driver and enclave targets. Specifically, it
ensures that `demo_driver.cc` is compiled with the host crosstool, the enclave
data dependencies are compiled with the SGX crosstool, and that `demo_driver` is
invoked with flags that specify the enclaves' paths. For one enclave dependency,
the flag name is always `--enclave_path`, but for multiple enclave dependencies
each enclave is passed with a flag matching its target name (e.g., for
dependencies on enclaves `//pkg0:enclave0` and `//pkg1:enclave1`, the binary is
passed arguments `--enclave0="path/to/pkg0/enclave0_signed.so"` and
`--enclave1="path/to/pkg1/enclave1_signed.so"`).

Let's try building the demo enclave. First, navigate to the examples directory:

```shell
$ cd asylo/examples
```

Next, we build our example:

```shell
$ bazel build --config=enc-sim quickstart
```

Note: This command will build an enclave that runs in simulation
mode[^simulation_mode]. Hardware support in Asylo will come in a later release.

## Running an enclave application

Now that we have built the target, let's run the example:

```shell
$ (cd bazel-bin/quickstart/quickstart.runfiles/asylo_examples; quickstart/quickstart)
```

You will be prompted to enter a message. Type whatever you like, and you will
see an encrypted message, like this:

```shell
Please enter a message to encrypt:
Hello World!
Encrypted message:
[`oy})Cvyi}2
```

Of course, your encrypted message will be different from this example if you
type a different message from "Hello World!". Let's see whether we can decrypt
the message correctly. Run the enclave again and enter your encrypted message
from the last run:

```shell
Please enter a message to encrypt:
[`oy})Cvyi}2
Encrypted message:
Hello World!
```

We got our original message! The algorithm to encrypt the message is a simple
XOR operation so encryption and decryption are symmetric operations:

```
const string EncryptMessage(const string &message) {
  const string encrypt_key = "SecurityKey";
  string encrypt_message = message;
  for (int i = 0; i < message.size(); ++i) {
    // Input should all be ascii 32 -127, So we do an xor for only the last
    // 5 bits, and ignore the first bit to keep the encrypted char to be within
    // ascii 32 - 127.
    char sixth_and_seventh_bits = message[i] & 0x60;
    char last_five_bits = message[i] & 0x1F;
    char key_last_five_bits = encrypt_key[i % encrypt_key.size()] & 0x1F;
    encrypt_message[i] =
        sixth_and_seventh_bits | (last_five_bits ^ key_last_five_bits);
  }
  return encrypt_message;
}
```

Note: the demo executed with `blaze run` is not interactive because blaze closes
stdin.

## Summary exercise

Now you know enough about Asylo to begin modifying an enclave application. As
you can see, our current example does not make use of the `output` parameter
passed to `Run`. We simply pass a null pointer as output argument when calling
`EnterAndRun`. Let's modify the code to generate some output.

-   In the `demo_enclave.cc` file, modify the `Run` method to store the
    encrypted message in output instead of printing it. The sample code provides
    a method called `SetEnclaveOutputMessage` for modifying output.
-   In the `demo_driver.cc` file, print the output generated by the enclave
    after the call to `EnterAndRun`. The sample code provides a method called
    `GetEnclaveOutputMessage` for getting the string from output. You should see
    exactly the same results as before.
-   The `EnterAndRun` function could be called multiple times once the enclave
    is initialized. In the end of Part 2 code of `demo_driver.cc` file, write
    code to take two input strings, combine them, and send them to the enclave
    by calling the `EnterAndRun` function again. After making this change, you
    should see both `EnterAndRun` calls executed.

Sample output:

```shell
Please enter a message to encrypt:
HelloWorld!
Encrypted Message:
[`oy}^{kga8
Please enter a message to encrypt:
Hello
Please enter a message to encrypt:
World!
Encrypted Message:
[`oy}^{kga8
```

## Related materials

-   [Intel Software Guard Extensions SDK for Linux
    OS](https://drive.google.com/file/d/0B6-ychTRrhfJZkxvSFFfUl96dTg/view)
    explains the mechanism of Intel SGX technology.

## Notes

[^simulation_mode]: The simulated mode closely emulates the SGX environment in
                    software. It does not require the use of SGX hardware or
                    drivers and, consequently, does *not* provide the same
                    security guarantees as SGX hardware.
