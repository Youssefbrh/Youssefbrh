#!/usr/bin/env python3
"""Generate NotchNova.xcodeproj/project.pbxproj from the files on disk.

Deterministic: object IDs are derived from file paths, so re-running after
adding/removing Swift files updates the project without noise. objectVersion
56 keeps the project openable by Xcode 15 and newer.

Usage: python3 tools/genproj.py   (from the repo root)
"""

import hashlib
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = "NotchNova"
PROJECT_NAME = "NotchNova"
BUNDLE_ID = "com.youssef.notchnova"
DEPLOYMENT_TARGET = "14.0"


def uid(seed: str) -> str:
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()


def collect():
    """Return (sorted swift file relpaths, sorted dir relpaths) under SRC_DIR."""
    swift_files, dirs = [], set()
    base = os.path.join(ROOT, SRC_DIR)
    for dirpath, dirnames, filenames in os.walk(base):
        dirnames.sort()
        rel_dir = os.path.relpath(dirpath, base)
        if rel_dir != ".":
            dirs.add(rel_dir)
        for name in sorted(filenames):
            if name.endswith(".swift"):
                rel = name if rel_dir == "." else f"{rel_dir}/{name}"
                swift_files.append(rel)
    return swift_files, sorted(dirs)


def main():
    swift_files, dirs = collect()
    if not swift_files:
        sys.exit("no swift files found under NotchNova/")

    ids = {
        "project": uid("pbx:project"),
        "mainGroup": uid("group:<main>"),
        "productsGroup": uid("group:<products>"),
        "srcRootGroup": uid("group:" + SRC_DIR),
        "target": uid("pbx:target"),
        "product": uid("ref:product.app"),
        "sourcesPhase": uid("phase:sources"),
        "frameworksPhase": uid("phase:frameworks"),
        "resourcesPhase": uid("phase:resources"),
        "projCfgList": uid("cfglist:project"),
        "targetCfgList": uid("cfglist:target"),
        "projDebug": uid("cfg:project:debug"),
        "projRelease": uid("cfg:project:release"),
        "targetDebug": uid("cfg:target:debug"),
        "targetRelease": uid("cfg:target:release"),
        "infoPlist": uid("ref:App/Info.plist"),
    }

    file_ref = {f: uid("ref:" + f) for f in swift_files}
    build_file = {f: uid("build:" + f) for f in swift_files}
    group_id = {d: uid("group:" + SRC_DIR + "/" + d) for d in dirs}

    def group_children(rel_dir):
        """Direct children (subgroup ids + file ref ids) of a dir, sorted dirs-first."""
        children = []
        for d in dirs:
            parent = os.path.dirname(d)
            if (rel_dir == "" and parent == "") or parent == rel_dir:
                if d != rel_dir:
                    children.append((os.path.basename(d), group_id[d], "group"))
        for f in swift_files:
            parent = os.path.dirname(f)
            if parent == rel_dir:
                children.append((os.path.basename(f), file_ref[f], "file"))
        if rel_dir == "App":
            children.append(("Info.plist", ids["infoPlist"], "file"))
        children.sort(key=lambda c: (c[2] != "group", c[0].lower()))
        return children

    out = []
    w = out.append

    w("// !$*UTF8*$!")
    w("{")
    w("\tarchiveVersion = 1;")
    w("\tclasses = {\n\t};")
    w("\tobjectVersion = 56;")
    w("\tobjects = {")

    # --- PBXBuildFile
    w("\n/* Begin PBXBuildFile section */")
    for f in swift_files:
        name = os.path.basename(f)
        w(f"\t\t{build_file[f]} /* {name} in Sources */ = {{isa = PBXBuildFile; "
          f"fileRef = {file_ref[f]} /* {name} */; }};")
    w("/* End PBXBuildFile section */")

    # --- PBXFileReference
    w("\n/* Begin PBXFileReference section */")
    w(f"\t\t{ids['product']} /* {PROJECT_NAME}.app */ = {{isa = PBXFileReference; "
      f"explicitFileType = wrapper.application; includeInIndex = 0; "
      f"path = {PROJECT_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    w(f"\t\t{ids['infoPlist']} /* Info.plist */ = {{isa = PBXFileReference; "
      f"lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
    for f in swift_files:
        name = os.path.basename(f)
        w(f"\t\t{file_ref[f]} /* {name} */ = {{isa = PBXFileReference; "
          f"lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};")
    w("/* End PBXFileReference section */")

    # --- PBXFrameworksBuildPhase
    w("\n/* Begin PBXFrameworksBuildPhase section */")
    w(f"\t\t{ids['frameworksPhase']} /* Frameworks */ = {{")
    w("\t\t\tisa = PBXFrameworksBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (\n\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXFrameworksBuildPhase section */")

    # --- PBXGroup
    w("\n/* Begin PBXGroup section */")

    w(f"\t\t{ids['mainGroup']} = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{ids['srcRootGroup']} /* {SRC_DIR} */,")
    w(f"\t\t\t\t{ids['productsGroup']} /* Products */,")
    w("\t\t\t);")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    w(f"\t\t{ids['productsGroup']} /* Products */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{ids['product']} /* {PROJECT_NAME}.app */,")
    w("\t\t\t);")
    w("\t\t\tname = Products;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    w(f"\t\t{ids['srcRootGroup']} /* {SRC_DIR} */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    for name, cid, _ in group_children(""):
        w(f"\t\t\t\t{cid} /* {name} */,")
    w("\t\t\t);")
    w(f"\t\t\tpath = {SRC_DIR};")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    for d in dirs:
        w(f"\t\t{group_id[d]} /* {os.path.basename(d)} */ = {{")
        w("\t\t\tisa = PBXGroup;")
        w("\t\t\tchildren = (")
        for name, cid, _ in group_children(d):
            w(f"\t\t\t\t{cid} /* {name} */,")
        w("\t\t\t);")
        w(f"\t\t\tpath = {os.path.basename(d)};")
        w("\t\t\tsourceTree = \"<group>\";")
        w("\t\t};")
    w("/* End PBXGroup section */")

    # --- PBXNativeTarget
    w("\n/* Begin PBXNativeTarget section */")
    w(f"\t\t{ids['target']} /* {PROJECT_NAME} */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {ids['targetCfgList']} "
      f"/* Build configuration list for PBXNativeTarget \"{PROJECT_NAME}\" */;")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{ids['sourcesPhase']} /* Sources */,")
    w(f"\t\t\t\t{ids['frameworksPhase']} /* Frameworks */,")
    w(f"\t\t\t\t{ids['resourcesPhase']} /* Resources */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = (\n\t\t\t);")
    w("\t\t\tdependencies = (\n\t\t\t);")
    w(f"\t\t\tname = {PROJECT_NAME};")
    w(f"\t\t\tproductName = {PROJECT_NAME};")
    w(f"\t\t\tproductReference = {ids['product']} /* {PROJECT_NAME}.app */;")
    w("\t\t\tproductType = \"com.apple.product-type.application\";")
    w("\t\t};")
    w("/* End PBXNativeTarget section */")

    # --- PBXProject
    w("\n/* Begin PBXProject section */")
    w(f"\t\t{ids['project']} /* Project object */ = {{")
    w("\t\t\tisa = PBXProject;")
    w("\t\t\tattributes = {")
    w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    w("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    w("\t\t\t\tLastUpgradeCheck = 1500;")
    w("\t\t\t\tTargetAttributes = {")
    w(f"\t\t\t\t\t{ids['target']} = {{")
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    w("\t\t\t\t\t};")
    w("\t\t\t\t};")
    w("\t\t\t};")
    w(f"\t\t\tbuildConfigurationList = {ids['projCfgList']} "
      f"/* Build configuration list for PBXProject \"{PROJECT_NAME}\" */;")
    w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    w("\t\t\tdevelopmentRegion = en;")
    w("\t\t\thasScannedForEncodings = 0;")
    w("\t\t\tknownRegions = (\n\t\t\t\ten,\n\t\t\t\tBase,\n\t\t\t);")
    w(f"\t\t\tmainGroup = {ids['mainGroup']};")
    w(f"\t\t\tproductRefGroup = {ids['productsGroup']} /* Products */;")
    w("\t\t\tprojectDirPath = \"\";")
    w("\t\t\tprojectRoot = \"\";")
    w("\t\t\ttargets = (")
    w(f"\t\t\t\t{ids['target']} /* {PROJECT_NAME} */,")
    w("\t\t\t);")
    w("\t\t};")
    w("/* End PBXProject section */")

    # --- PBXResourcesBuildPhase
    w("\n/* Begin PBXResourcesBuildPhase section */")
    w(f"\t\t{ids['resourcesPhase']} /* Resources */ = {{")
    w("\t\t\tisa = PBXResourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (\n\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXResourcesBuildPhase section */")

    # --- PBXSourcesBuildPhase
    w("\n/* Begin PBXSourcesBuildPhase section */")
    w(f"\t\t{ids['sourcesPhase']} /* Sources */ = {{")
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for f in swift_files:
        w(f"\t\t\t\t{build_file[f]} /* {os.path.basename(f)} in Sources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXSourcesBuildPhase section */")

    # --- XCBuildConfiguration
    common_project = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_C_LANGUAGE_STANDARD": "gnu17",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "MACOSX_DEPLOYMENT_TARGET": DEPLOYMENT_TARGET,
        "SDKROOT": "macosx",
    }
    debug_project = {
        **common_project,
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_TESTABILITY": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "GCC_PREPROCESSOR_DEFINITIONS": '(\n\t\t\t\t\t"DEBUG=1",\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t)',
        "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        "ONLY_ACTIVE_ARCH": "YES",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
    }
    release_project = {
        **common_project,
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"',
        "ENABLE_NS_ASSERTIONS": "NO",
        "MTL_ENABLE_DEBUG_INFO": "NO",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_OPTIMIZATION_LEVEL": '"-O"',
    }
    target_settings = {
        "CODE_SIGN_IDENTITY": '"-"',
        "CODE_SIGN_STYLE": "Automatic",
        "COMBINE_HIDPI_IMAGES": "YES",
        "CURRENT_PROJECT_VERSION": "1",
        "ENABLE_HARDENED_RUNTIME": "NO",
        "GENERATE_INFOPLIST_FILE": "NO",
        "INFOPLIST_FILE": f"{SRC_DIR}/App/Info.plist",
        "LD_RUNPATH_SEARCH_PATHS": '(\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"@executable_path/../Frameworks",\n\t\t\t\t)',
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
        "PRODUCT_NAME": '"$(TARGET_NAME)"',
        "SWIFT_VERSION": "5.0",
    }

    def emit_config(cfg_id, name, settings):
        w(f"\t\t{cfg_id} /* {name} */ = {{")
        w("\t\t\tisa = XCBuildConfiguration;")
        w("\t\t\tbuildSettings = {")
        for key in sorted(settings):
            w(f"\t\t\t\t{key} = {settings[key]};")
        w("\t\t\t};")
        w(f"\t\t\tname = {name};")
        w("\t\t};")

    w("\n/* Begin XCBuildConfiguration section */")
    emit_config(ids["projDebug"], "Debug", debug_project)
    emit_config(ids["projRelease"], "Release", release_project)
    emit_config(ids["targetDebug"], "Debug", target_settings)
    emit_config(ids["targetRelease"], "Release", target_settings)
    w("/* End XCBuildConfiguration section */")

    # --- XCConfigurationList
    w("\n/* Begin XCConfigurationList section */")
    for list_id, owner, debug_id, release_id in [
        (ids["projCfgList"], f'PBXProject "{PROJECT_NAME}"', ids["projDebug"], ids["projRelease"]),
        (ids["targetCfgList"], f'PBXNativeTarget "{PROJECT_NAME}"', ids["targetDebug"], ids["targetRelease"]),
    ]:
        w(f"\t\t{list_id} /* Build configuration list for {owner} */ = {{")
        w("\t\t\tisa = XCConfigurationList;")
        w("\t\t\tbuildConfigurations = (")
        w(f"\t\t\t\t{debug_id} /* Debug */,")
        w(f"\t\t\t\t{release_id} /* Release */,")
        w("\t\t\t);")
        w("\t\t\tdefaultConfigurationIsVisible = 0;")
        w("\t\t\tdefaultConfigurationName = Release;")
        w("\t\t};")
    w("/* End XCConfigurationList section */")

    w("\t};")
    w(f"\trootObject = {ids['project']} /* Project object */;")
    w("}")

    proj_dir = os.path.join(ROOT, f"{PROJECT_NAME}.xcodeproj")
    os.makedirs(proj_dir, exist_ok=True)
    with open(os.path.join(proj_dir, "project.pbxproj"), "w") as fh:
        fh.write("\n".join(out) + "\n")
    print(f"wrote {PROJECT_NAME}.xcodeproj/project.pbxproj "
          f"({len(swift_files)} sources, {len(dirs)} groups)")


if __name__ == "__main__":
    main()
