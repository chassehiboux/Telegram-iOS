
load("@build_bazel_rules_apple//apple:ios.bzl", "ios_unit_test")
load("@build_bazel_rules_apple//apple/testing/default_runner:ios_test_runner.bzl", "ios_test_runner")

objc_library(
    name = "MtProtoKit",
    enable_modules = True,
    module_name = "MtProtoKit",
    srcs = glob([
        "Sources/**/*.m",
        "Sources/**/*.h",
    ]),
    copts = [
        "-Werror",
    ],
    hdrs = glob([
        "PublicHeaders/**/*.h",
    ]),
    includes = [
        "PublicHeaders",
    ],
    deps = [
        "//submodules/EncryptionProvider:EncryptionProvider",
    ],
    sdk_frameworks = [
        "Foundation",
        "Security",
        "SystemConfiguration",
        "CFNetwork",
    ],
    sdk_dylibs = [
        "libz",
    ],
    visibility = [
        "//visibility:public",
    ],
)

objc_library(
    name = "MtProtoKitProxyTestsLib",
    testonly = True,
    srcs = glob(["Tests/**/*.m"]),
    deps = [":MtProtoKit"],
    sdk_frameworks = [
        "Foundation",
        "XCTest",
    ],
)

ios_test_runner(
    name = "MtProtoKitProxyTestRunner",
    device_type = "iPhone 17",
    os_version = "26.2",
)

ios_unit_test(
    name = "MtProtoKitProxyTests",
    minimum_os_version = "13.0",
    runner = ":MtProtoKitProxyTestRunner",
    deps = [":MtProtoKitProxyTestsLib"],
    visibility = ["//visibility:public"],
)
