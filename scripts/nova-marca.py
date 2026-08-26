#!/usr/bin/env python3
"""Cria um escritório novo no white label: pasta da marca + target + scheme.

    python3 scripts/nova-marca.py \\
        --id silva-associados \\
        --nome "Silva & Associados" \\
        --razao "Silva & Associados Advogados" \\
        --bundle br.adv.silvaassociados.app

O que este script NÃO faz, de propósito: escolher as cores e os logotipos. Ele
gera os placeholders em cinza neutro com os nomes exatos que o núcleo espera, e
lista o que falta. Copiar o catálogo de outra marca economizaria dois minutos e
já colocou app de escritório na loja com a cor do concorrente.

Rode a partir da raiz do repositório. Não escreve nada se a marca já existir.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PBXPROJ = ROOT / "AdvClient.xcodeproj" / "project.pbxproj"
SCHEMES = ROOT / "AdvClient.xcodeproj" / "xcshareddata" / "xcschemes"

# Cinza neutro: visivelmente "não configurado" sem ser ilegível na tela.
PLACEHOLDER_COLORS = {
    "BrandPrimary":    ("0.204", "0.227", "0.275"),
    "BrandSecondary":  ("0.318", "0.361", "0.435"),
    "BrandMuted":      ("0.427", "0.451", "0.502"),
    "BrandBody":       ("0.145", "0.169", "0.227"),
    "BrandBackground": ("0.937", "0.945", "0.961"),
    "BrandCard":       ("1.000", "1.000", "1.000"),
    "BrandOnBrand":    ("1.000", "1.000", "1.000"),
    "BrandLine":       ("0.894", "0.914", "0.945"),
    "BrandFill":       ("0.949", "0.961", "0.980"),
    "BrandBrass":      ("0.659", "0.506", "0.247"),
    "AccentColor":     ("0.204", "0.227", "0.275"),
}
IMAGESETS = ["LogoHorizontal", "LogoVertical"]


def die(message: str) -> None:
    sys.exit(f"erro: {message}")


def object_id(seed: str, index: int) -> str:
    """ID de 24 hex estável por marca — o mesmo comando gera o mesmo projeto."""
    digest = hashlib.sha1(f"{seed}:{index}".encode()).hexdigest().upper()
    return ("BB" + digest)[:24]


def target_name_from(display: str) -> str:
    name = re.sub(r"[^A-Za-z0-9]", "", display)
    if not name or name[0].isdigit():
        die(f"não consegui derivar um nome de target a partir de {display!r}; use --target")
    return name


# ─────────────────────────── arquivos da marca ───────────────────────────


def write_color(path: Path, rgb: tuple[str, str, str]) -> None:
    red, green, blue = rgb
    path.mkdir(parents=True, exist_ok=True)
    (path / "Contents.json").write_text(json.dumps({
        "colors": [{
            "color": {
                "color-space": "srgb",
                "components": {"alpha": "1.000", "blue": blue, "green": green, "red": red},
            },
            "idiom": "universal",
        }],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")


def create_brand_folder(args, target: str) -> Path:
    brand = ROOT / "Brands" / target
    if brand.exists():
        die(f"{brand.relative_to(ROOT)} já existe — apague a pasta ou escolha outro --target")

    resources = brand / "Resources"
    assets = resources / "Assets.xcassets"
    assets.mkdir(parents=True)
    (assets / "Contents.json").write_text(
        json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")

    for name, rgb in PLACEHOLDER_COLORS.items():
        write_color(assets / f"{name}.colorset", rgb)

    for name in IMAGESETS:
        d = assets / f"{name}.imageset"
        d.mkdir()
        (d / "Contents.json").write_text(json.dumps({
            "images": [{"idiom": "universal", "scale": f"{s}x"} for s in (1, 2, 3)],
            "info": {"author": "xcode", "version": 1},
        }, indent=2) + "\n")

    appicon = assets / "AppIcon.appiconset"
    appicon.mkdir()
    (appicon / "Contents.json").write_text(json.dumps({
        "images": [{"idiom": "universal", "platform": "ios", "size": "1024x1024"}],
        "info": {"author": "xcode", "version": 1},
    }, indent=2) + "\n")

    (resources / "Fonts").mkdir()
    (resources / "Fonts" / "README.txt").write_text(
        "Coloque aqui os .ttf/.otf da fonte da marca.\n"
        "São registrados no lançamento por Theme.registerBundledFonts(),\n"
        "sem entrada no Info.plist. O nome da família vai em Brand.json → fontFamily.\n"
        "Sem os arquivos, o app cai na fonte do sistema.\n")

    (resources / "Brand.json").write_text(json.dumps({
        "id": args.id,
        "displayName": args.nome,
        "legalName": args.razao,
        "fontFamily": args.fonte,
        "tagline": {"pt-BR": "DEFINIR", "en": "TO DEFINE"},
        "contact": {
            "phone": "+55 00 0000-0000",
            "whatsapp": "+55 00 90000-0000",
            "email": f"contato@{args.dominio}" if args.dominio else "DEFINIR",
            "website": f"https://{args.dominio}" if args.dominio else "DEFINIR",
            "instagram": None,
            "linkedin": None,
            "address": "DEFINIR",
            "city": "DEFINIR",
            "businessHours": {"pt-BR": "seg a sex, 9h–18h", "en": "Mon–Fri, 9am–6pm"},
        },
        "api": {"baseURL": f"https://api.{args.dominio}" if args.dominio else "DEFINIR"},
        "store": {"appStoreID": None},
    }, ensure_ascii=False, indent=2) + "\n")

    (brand / "Brand.xcconfig").write_text(
        f"// Marca: {args.razao}.\n"
        "//\n"
        "// Este arquivo e o Brand.json ao lado são tudo que um escritório novo\n"
        "// precisa escrever — o resto vem do núcleo.\n"
        "\n"
        '#include "../../Config/App.xcconfig"\n'
        "\n"
        f"BRAND_ID = {args.id}\n"
        f"BRAND_DIR = Brands/{target}\n"
        f"BRAND_DISPLAY_NAME = {args.nome}\n"
        f"BRAND_BUNDLE_ID = {args.bundle}\n")

    shutil.copyfile(ROOT / "Brands" / "JordanNeves" / "Info.plist", brand / "Info.plist")
    return brand


# ─────────────────────────── injeção no projeto ───────────────────────────


def insert_before(text: str, anchor: str, block: str) -> str:
    if text.count(anchor) != 1:
        die(f"âncora ausente ou ambígua no project.pbxproj: {anchor!r}")
    return text.replace(anchor, block + anchor)


def patch_pbxproj(target: str, ids: dict[str, str]) -> None:
    text = PBXPROJ.read_text()
    if f"/* {target} */" in text:
        die(f"o projeto já tem referências a {target}")

    text = insert_before(text, "/* End PBXFileReference section */", (
        f'\t\t{ids["product"]} /* {target}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {target}.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n'
        f'\t\t{ids["xcconfig"]} /* Brand.xcconfig */ = {{isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = Brand.xcconfig; sourceTree = "<group>"; }};\n'
        f'\t\t{ids["plist"]} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};\n'))

    text = insert_before(text, "/* End PBXFileSystemSynchronizedRootGroup section */", (
        f'\t\t{ids["sync"]} /* {target} */ = {{\n'
        f'\t\t\tisa = PBXFileSystemSynchronizedRootGroup;\n'
        f'\t\t\tname = {target};\n'
        f'\t\t\tpath = "Brands/{target}/Resources";\n'
        f'\t\t\tsourceTree = "<group>";\n'
        f'\t\t}};\n'))

    # Grupo raiz e grupo Brands
    text = insert_before(text, "\t\t\t\tAA0000000000000000000027 /* Brands */,",
                         f'\t\t\t\t{ids["sync"]} /* {target} */,\n')
    text = insert_before(text, "\t\t\t\tAA0000000000000000000011 /* AdvClientTests.xctest */,",
                         f'\t\t\t\t{ids["product"]} /* {target}.app */,\n')
    text = insert_before(text, "\t\t\t\tAA0000000000000000000028 /* JordanNeves */,",
                         f'\t\t\t\t{ids["group"]} /* {target} */,\n')
    text = insert_before(text, "/* End PBXGroup section */", (
        f'\t\t{ids["group"]} /* {target} */ = {{\n'
        f'\t\t\tisa = PBXGroup;\n'
        f'\t\t\tchildren = (\n'
        f'\t\t\t\t{ids["xcconfig"]} /* Brand.xcconfig */,\n'
        f'\t\t\t\t{ids["plist"]} /* Info.plist */,\n'
        f'\t\t\t);\n'
        f'\t\t\tpath = {target};\n'
        f'\t\t\tsourceTree = "<group>";\n'
        f'\t\t}};\n'))

    # Fases de build
    text = insert_before(text, "/* End PBXFrameworksBuildPhase section */", (
        f'\t\t{ids["frameworks"]} /* Frameworks */ = {{\n'
        f'\t\t\tisa = PBXFrameworksBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n'
        f'\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n'))
    text = insert_before(text, "/* End PBXSourcesBuildPhase section */", (
        f'\t\t{ids["sources"]} /* Sources */ = {{\n'
        f'\t\t\tisa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n'
        f'\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n'))
    text = insert_before(text, "/* End PBXResourcesBuildPhase section */", (
        f'\t\t{ids["resources"]} /* Resources */ = {{\n'
        f'\t\t\tisa = PBXResourcesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n'
        f'\t\t\tfiles = (\n\t\t\t);\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n'))

    # Target
    text = insert_before(text, "/* End PBXNativeTarget section */", (
        f'\t\t{ids["target"]} /* {target} */ = {{\n'
        f'\t\t\tisa = PBXNativeTarget;\n'
        f'\t\t\tbuildConfigurationList = {ids["configlist"]} /* Build configuration list for PBXNativeTarget "{target}" */;\n'
        f'\t\t\tbuildPhases = (\n'
        f'\t\t\t\t{ids["sources"]} /* Sources */,\n'
        f'\t\t\t\t{ids["frameworks"]} /* Frameworks */,\n'
        f'\t\t\t\t{ids["resources"]} /* Resources */,\n'
        f'\t\t\t);\n\t\t\tbuildRules = (\n\t\t\t);\n\t\t\tdependencies = (\n\t\t\t);\n'
        f'\t\t\tfileSystemSynchronizedGroups = (\n'
        f'\t\t\t\tAA0000000000000000000001 /* AdvClient */,\n'
        f'\t\t\t\t{ids["sync"]} /* {target} */,\n'
        f'\t\t\t);\n'
        f'\t\t\tname = {target};\n\t\t\tpackageProductDependencies = (\n\t\t\t);\n'
        f'\t\t\tproductName = {target};\n'
        f'\t\t\tproductReference = {ids["product"]} /* {target}.app */;\n'
        f'\t\t\tproductType = "com.apple.product-type.application";\n\t\t}};\n'))

    # Configurações de build
    for kind in ("Debug", "Release"):
        text = insert_before(text, "/* End XCBuildConfiguration section */", (
            f'\t\t{ids[kind.lower()]} /* {kind} */ = {{\n'
            f'\t\t\tisa = XCBuildConfiguration;\n'
            f'\t\t\tbaseConfigurationReference = {ids["xcconfig"]} /* Brand.xcconfig */;\n'
            f'\t\t\tbuildSettings = {{\n\t\t\t}};\n'
            f'\t\t\tname = {kind};\n\t\t}};\n'))
    text = insert_before(text, "/* End XCConfigurationList section */", (
        f'\t\t{ids["configlist"]} /* Build configuration list for PBXNativeTarget "{target}" */ = {{\n'
        f'\t\t\tisa = XCConfigurationList;\n\t\t\tbuildConfigurations = (\n'
        f'\t\t\t\t{ids["debug"]} /* Debug */,\n\t\t\t\t{ids["release"]} /* Release */,\n'
        f'\t\t\t);\n\t\t\tdefaultConfigurationIsVisible = 0;\n'
        f'\t\t\tdefaultConfigurationName = Release;\n\t\t}};\n'))

    # Projeto: lista de targets e atributos
    text = insert_before(text, "\t\t\t\tAA0000000000000000000012 /* AdvClientTests */,",
                         f'\t\t\t\t{ids["target"]} /* {target} */,\n')
    text = insert_before(text, "\t\t\t\t\tAA0000000000000000000012 = {",
                         f'\t\t\t\t\t{ids["target"]} = {{\n'
                         f'\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;\n\t\t\t\t\t}};\n')

    PBXPROJ.write_text(text)


def write_scheme(target: str, ids: dict[str, str]) -> None:
    (SCHEMES / f"{target}.xcscheme").write_text(f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "1600" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ids['target']}"
               BuildableName = "{target}.app"
               BlueprintName = "{target}"
               ReferencedContainer = "container:AdvClient.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ids['target']}"
            BuildableName = "{target}.app"
            BlueprintName = "{target}"
            ReferencedContainer = "container:AdvClient.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ids['target']}"
            BuildableName = "{target}.app"
            BlueprintName = "{target}"
            ReferencedContainer = "container:AdvClient.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug"></AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES"></ArchiveAction>
</Scheme>
""")


def main() -> None:
    parser = argparse.ArgumentParser(description="Cria um escritório novo no white label.")
    parser.add_argument("--id", required=True, help="identificador em minúsculas, ex.: silva-associados")
    parser.add_argument("--nome", required=True, help="nome curto, aparece sob o ícone")
    parser.add_argument("--razao", required=True, help="razão social, aparece no perfil e na abertura")
    parser.add_argument("--bundle", required=True, help="bundle identifier, ex.: br.adv.silva.app")
    parser.add_argument("--target", help="nome do target; derivado de --nome se omitido")
    parser.add_argument("--fonte", default="Montserrat", help="família da fonte da marca")
    parser.add_argument("--dominio", help="domínio do escritório, ex.: silva.adv.br")
    args = parser.parse_args()

    if not PBXPROJ.exists():
        die("rode a partir da raiz do repositório")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", args.id):
        die("--id aceita minúsculas, números e hífen")
    if not re.fullmatch(r"[A-Za-z0-9.-]+", args.bundle):
        die("--bundle inválido")

    target = args.target or target_name_from(args.nome)
    keys = ["product", "xcconfig", "plist", "sync", "group", "target",
            "sources", "frameworks", "resources", "debug", "release", "configlist"]
    ids = {k: object_id(target, i) for i, k in enumerate(keys)}
    if len(set(ids.values())) != len(keys):
        die("colisão de identificadores — mude o --target")

    brand = create_brand_folder(args, target)
    patch_pbxproj(target, ids)
    write_scheme(target, ids)

    print(f"marca {target} criada.\n")
    print("Falta você fazer, antes de qualquer build para a loja:")
    print(f"  1. Cores em {brand.relative_to(ROOT)}/Resources/Assets.xcassets/Brand*.colorset")
    print("     (estão em cinza neutro de propósito — nenhuma marca herda a cor de outra)")
    print(f"  2. logo-horizontal / logo-vertical nos imagesets e o AppIcon de 1024px")
    print(f"  3. Os campos DEFINIR em {brand.relative_to(ROOT)}/Resources/Brand.json")
    print(f"  4. Fontes .ttf em {brand.relative_to(ROOT)}/Resources/Fonts/")
    print(f"\nDepois: abra o Xcode, escolha o scheme {target} e rode.")


if __name__ == "__main__":
    main()
