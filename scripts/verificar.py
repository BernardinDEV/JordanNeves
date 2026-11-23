#!/usr/bin/env python3
"""Verificações estáticas do repositório. Não substitui o build — complementa.

    python3 scripts/verificar.py

Existe porque a maior parte do trabalho neste projeto acontece sem Xcode à mão,
e porque um erro já passou: a descrição do Face ID sumiu do Info.plist de uma
marca quando o Xcode a migrou para o build setting e o setting foi removido
depois. Nada acusou; o app encerrava na primeira leitura biométrica.

Sai com 1 se houver falha, para servir de passo de CI.
"""

from __future__ import annotations

import json
import re
import sys
import xml.dom.minidom
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORE = ROOT / "AdvClient"
BRANDS = ROOT / "Brands"
PBXPROJ = ROOT / "AdvClient.xcodeproj" / "project.pbxproj"
CATALOG = CORE / "Resources" / "Localizable.xcstrings"

# Chaves de Info.plist que o código exige. A ausência de cada uma é uma falha em
# runtime, não de compilação — por isso precisam ser conferidas aqui.
REQUIRED_PLIST_KEYS = {
    "NSFaceIDUsageDescription":
        "Core/Security/BiometricAuthenticator chama evaluatePolicy; sem esta "
        "chave o iOS encerra o app, e canEvaluatePolicy não avisa antes.",
}

# Onde um nome de marca pode aparecer fora de Brands/ por decisão registrada.
BRAND_MENTION_ALLOWLIST = {
    "Config/Tests.xcconfig",   # TEST_HOST_TARGET precisa de um target concreto
}

falhas: list[str] = []
avisos: list[str] = []


def falha(msg: str) -> None:
    falhas.append(msg)


def aviso(msg: str) -> None:
    avisos.append(msg)


def sem_comentarios(texto: str) -> str:
    """Descarta comentários de linha para não acusar prosa explicativa."""
    corpo = []
    for linha in texto.split("\n"):
        limpa = linha.split("//")[0] if "//" in linha else linha
        corpo.append(limpa)
    return "\n".join(corpo)


def marcas() -> list[Path]:
    return sorted(p for p in BRANDS.iterdir() if p.is_dir())


# ── 1. Projeto ──────────────────────────────────────────────────────────────

def checar_projeto() -> None:
    t = PBXPROJ.read_text()
    if t.count("{") != t.count("}"):
        falha(f"project.pbxproj: chaves desbalanceadas ({t.count('{') - t.count('}'):+d})")

    definidos = set(re.findall(r"^\t\t([0-9A-F]{24}) [/=]", t, re.M))
    citados = set(re.findall(r"\b([0-9A-F]{24})\b", t))
    if orfaos := citados - definidos:
        falha(f"project.pbxproj: referências a objetos inexistentes: {sorted(orfaos)}")

    todos = re.findall(r"^\t\t([0-9A-F]{24}) [/=]", t, re.M)
    if dup := {i for i in todos if todos.count(i) > 1}:
        falha(f"project.pbxproj: identificadores duplicados: {sorted(dup)}")

    if re.findall(r"/\* Begin (\w+) section \*/", t) != re.findall(r"/\* End (\w+) section \*/", t):
        falha("project.pbxproj: seções abertas e fechadas não batem")

    # Toda marca em Brands/ precisa de target, e todo target de marca precisa de scheme.
    alvos = set(re.findall(
        r"^\t\t[0-9A-F]{24} /\* (\S+) \*/ = \{\n\t\t\tisa = PBXNativeTarget;", t, re.M))
    schemes = {p.stem for p in (ROOT / "AdvClient.xcodeproj/xcshareddata/xcschemes").glob("*.xcscheme")}
    for marca in marcas():
        if marca.name not in alvos:
            falha(f"{marca.name}: pasta de marca sem target no projeto")
        elif marca.name not in schemes:
            aviso(f"{marca.name}: target sem scheme compartilhado — some para quem clonar")


# ── 2. Arquivos estruturados ────────────────────────────────────────────────

def checar_formatos() -> None:
    for f in ROOT.rglob("*.json"):
        if ".git" in f.parts:
            continue
        try:
            json.loads(f.read_text())
        except Exception as e:
            falha(f"{f.relative_to(ROOT)}: JSON inválido — {e}")
    for f in list(ROOT.rglob("*.xcstrings")):
        try:
            json.loads(f.read_text())
        except Exception as e:
            falha(f"{f.relative_to(ROOT)}: catálogo inválido — {e}")
    for f in list(BRANDS.rglob("Info.plist")) + list((ROOT / "AdvClient.xcodeproj").rglob("*.xcscheme")):
        try:
            xml.dom.minidom.parse(str(f))
        except Exception as e:
            falha(f"{f.relative_to(ROOT)}: XML inválido — {e}")


# ── 3. Info.plist de cada marca ─────────────────────────────────────────────

def configuracoes_da_marca(marca: Path) -> list[str]:
    """Os blocos XCBuildConfiguration (Debug, Release…) do target da marca.

    O target é achado pelo Brand.xcconfig que serve de base: o grupo da marca
    no projeto aponta para ele, e cada configuração do target o referencia.
    """
    projeto = PBXPROJ.read_text()
    grupo = re.search(
        r"\{\s*isa = PBXGroup;\s*children = \(([^)]*)\);[^}]*?path = " + re.escape(marca.name) + r";",
        projeto,
    )
    if not grupo:
        return []
    ref = re.search(r"(\w+) /\* Brand\.xcconfig \*/", grupo.group(1))
    if not ref:
        return []
    return re.findall(
        r"isa = XCBuildConfiguration;\s*baseConfigurationReference = " + ref.group(1) + r"[^}]*\}",
        projeto,
    )


def checar_plists() -> None:
    for marca in marcas():
        plist = marca / "Info.plist"
        if not plist.exists():
            falha(f"{marca.name}: sem Info.plist")
            continue
        texto = plist.read_text()
        xcconfigs = (marca / "Brand.xcconfig").read_text() + (ROOT / "Config" / "App.xcconfig").read_text()
        for chave, porque in REQUIRED_PLIST_KEYS.items():
            # Vale no arquivo ou num xcconfig. Nos ajustes do target não: lá
            # é exatamente o que checar_alvo_sem_ajustes recusa.
            no_arquivo = f"<key>{chave}</key>" in texto
            no_xcconfig = re.search(rf"^\s*INFOPLIST_KEY_{chave}\s*=", xcconfigs, re.M)
            if not (no_arquivo or no_xcconfig):
                falha(f"{marca.name}: falta {chave} no Info.plist. {porque}")


def checar_alvo_sem_ajustes() -> None:
    """O target de uma marca não pode ter ajuste de build próprio.

    Tudo vem de Config/App.xcconfig e do Brand.xcconfig da marca. Um valor
    gravado no target ganha dos dois em silêncio: o Brand.xcconfig continua
    dizendo uma coisa, o app sai com outra, e nova-marca.py não leva o valor
    para o escritório seguinte. É o que a aba General e a aba Info do Xcode
    fazem quando alguém edita nome, bundle id, equipe ou orientação ali.
    """
    for marca in marcas():
        configuracoes = configuracoes_da_marca(marca)
        if not configuracoes:
            falha(f"{marca.name}: não achei o target da marca no project.pbxproj")
            continue
        chaves: set[str] = set()
        for bloco in configuracoes:
            corpo = re.search(r"buildSettings = \{([^}]*)\}", bloco)
            if corpo:
                chaves.update(re.findall(r"^\s*([A-Za-z0-9_\[\]=*]+) =", corpo.group(1), re.M))
        if chaves:
            falha(
                f"{marca.name}: o target tem ajustes próprios ({', '.join(sorted(chaves))}) que "
                f"sobrepõem o Brand.xcconfig — mova os valores para Brands/{marca.name}/Brand.xcconfig "
                "e apague-os do target (Build Settings → selecionar → Delete)"
            )


# ── 4. Assets que o núcleo exige de toda marca ──────────────────────────────

def checar_assets() -> None:
    codigo = "\n".join(sem_comentarios(f.read_text()) for f in CORE.rglob("*.swift"))
    cores = set(re.findall(r'Color\(\s*"([A-Za-z][A-Za-z0-9_]*)"\s*\)', codigo))
    imagens = set(re.findall(r'Image\(\s*"([A-Za-z][A-Za-z0-9_]*)"\s*\)', codigo))

    for marca in marcas():
        catalogo = marca / "Resources" / "Assets.xcassets"
        if not catalogo.is_dir():
            falha(f"{marca.name}: sem Assets.xcassets")
            continue
        tem = {p.name.rsplit(".", 1)[0] for p in catalogo.iterdir() if p.is_dir()}
        for nome in sorted(cores - tem):
            falha(f"{marca.name}: o núcleo usa Color(\"{nome}\") e a marca não tem esse colorset")
        for nome in sorted(imagens - tem):
            falha(f"{marca.name}: o núcleo usa Image(\"{nome}\") e a marca não tem esse imageset")

        # Imageset sem arquivo nenhum rende imagem em branco, sem aviso de build.
        for pasta in catalogo.glob("*.imageset"):
            if not any(pasta.glob("*.png")) and not any(pasta.glob("*.pdf")):
                falha(f"{marca.name}: {pasta.name} não tem arquivo de imagem")


# ── 5. Brand.json completo ──────────────────────────────────────────────────

CAMPOS_MARCA = ["id", "displayName", "legalName", "fontFamily", "tagline", "contact", "api"]
CAMPOS_CONTATO = ["phone", "whatsapp", "email", "website", "address", "city", "businessHours"]


def checar_brand_json() -> None:
    for marca in marcas():
        caminho = marca / "Resources" / "Brand.json"
        if not caminho.exists():
            falha(f"{marca.name}: sem Brand.json")
            continue
        d = json.loads(caminho.read_text())
        for campo in CAMPOS_MARCA:
            if campo not in d:
                falha(f"{marca.name}/Brand.json: falta o campo {campo}")
        for campo in CAMPOS_CONTATO:
            if campo not in d.get("contact", {}):
                falha(f"{marca.name}/Brand.json: falta contact.{campo}")
        cru = caminho.read_text()
        if "DEFINIR" in cru or "TO DEFINE" in cru:
            aviso(f"{marca.name}/Brand.json: ainda tem campos DEFINIR")
        if "0000-0000" in cru or "example" in cru:
            aviso(f"{marca.name}/Brand.json: telefone ou domínio ainda é placeholder")

        for email in d.get("demo", {}).get("invitedEmails", []):
            if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", email):
                falha(f"{marca.name}/Brand.json: demo.invitedEmails tem '{email}', que não é um e-mail")

        modo = d.get("api", {}).get("mode", "demo")
        if modo not in ("demo", "remote", "readonly"):
            falha(f"{marca.name}/Brand.json: api.mode '{modo}' não existe — use demo, remote ou readonly")
        elif modo == "demo":
            aviso(f"{marca.name}/Brand.json: api.mode é demo — o app mostra dados de demonstração")
        elif modo == "readonly":
            aviso(f"{marca.name}/Brand.json: api.mode é readonly — fonte de teste, com a chave dentro "
                  "do Info.plist do app; não envie esta marca para a loja assim")
            segredos = ROOT / "Config" / "Secrets.xcconfig"
            texto = segredos.read_text() if segredos.exists() else ""
            if not re.search(r"^READONLY_API_KEY\s*=\s*\S", texto, re.M) or \
               not re.search(r"^READONLY_API_BASE_URL\s*=\s*https:", texto, re.M):
                falha(f"{marca.name}/Brand.json: api.mode é readonly, mas Config/Secrets.xcconfig não tem "
                      "READONLY_API_BASE_URL e READONLY_API_KEY (modelo: Config/Secrets.example.xcconfig)")

        fonte = d.get("fontFamily")
        pasta = marca / "Resources" / "Fonts"
        if fonte and not any(pasta.glob("*.ttf")) and not any(pasta.glob("*.otf")):
            aviso(f"{marca.name}: declara a fonte {fonte} e não empacota nenhum arquivo — "
                  "o app cai na fonte do sistema")


# ── 6. Nenhum escritório citado no núcleo ───────────────────────────────────

def checar_vazamento() -> None:
    termos: set[str] = set()
    for marca in marcas():
        d = json.loads((marca / "Resources" / "Brand.json").read_text())
        for valor in (marca.name, d.get("displayName"), d.get("legalName")):
            if valor:
                termos.update(p for p in str(valor).split() if len(p) > 3)

    alvos = list(CORE.rglob("*.swift")) + list((ROOT / "Config").glob("*.xcconfig"))
    for f in alvos:
        rel = str(f.relative_to(ROOT))
        if rel in BRAND_MENTION_ALLOWLIST:
            continue
        corpo = sem_comentarios(f.read_text())
        for termo in sorted(termos):
            if termo in corpo:
                falha(f"{rel}: cita '{termo}', que é de uma marca — o valor pertence ao Brand.json")


# ── 7. Localização ──────────────────────────────────────────────────────────

def checar_localizacao() -> None:
    d = json.loads(CATALOG.read_text())["strings"]
    pat = re.compile(r'(?:Text|Label|SectionHeader|Format\.string)\(\s*"([a-z][a-zA-Z0-9._]*)(?:\s|")')
    usadas: set[str] = set()
    for f in CORE.rglob("*.swift"):
        usadas.update(pat.findall(sem_comentarios(f.read_text())))

    for chave in sorted(usadas):
        if chave not in d and not any(k.split(" ")[0] == chave for k in d):
            falha(f"catálogo: o código usa '{chave}' e não há entrada — a tela mostra a chave crua")

    for chave, valor in sorted(d.items()):
        if not chave:
            continue
        idiomas = set(valor.get("localizations", {}))
        if not idiomas:
            aviso(f"catálogo: '{chave}' não tem tradução nenhuma")
        elif not {"pt-BR", "en"} <= idiomas:
            falha(f"catálogo: '{chave}' só tem {sorted(idiomas)} — o app é bilíngue")
        for lang, unidade in valor.get("localizations", {}).items():
            estado = unidade.get("stringUnit", {}).get("state")
            if estado and estado != "translated":
                aviso(f"catálogo: '{chave}' em {lang} está como '{estado}'")


# ── 8. Manifesto de privacidade ─────────────────────────────────────────────
#
# Sem manifesto, ou com uma API de motivo obrigatório sem declaração, o envio ao
# App Store Connect volta com ITMS-91053 — depois do build, do upload e da
# espera. Aqui o erro aparece antes.

MANIFESTO = CORE / "Resources" / "PrivacyInfo.xcprivacy"

# Categoria da Apple → padrões no código que a exigem.
APIS_DE_MOTIVO = {
    "NSPrivacyAccessedAPICategoryUserDefaults": [r"\bUserDefaults\b", r"@AppStorage"],
    "NSPrivacyAccessedAPICategoryFileTimestamp": [
        r"\.creationDate\b", r"\.modificationDate\b", r"contentModificationDate",
        r"attributesOfItem", r"\b(?:l|f)?stat\(", r"getattrlist",
    ],
    "NSPrivacyAccessedAPICategorySystemBootTime": [r"systemUptime", r"mach_absolute_time"],
    "NSPrivacyAccessedAPICategoryDiskSpace": [
        r"volumeAvailableCapacity", r"attributesOfFileSystem", r"systemFreeSize", r"\bstatfs\(",
    ],
    "NSPrivacyAccessedAPICategoryActiveKeyboards": [r"activeInputModes"],
}


def checar_privacidade() -> None:
    if not MANIFESTO.exists():
        falha("AdvClient/Resources/PrivacyInfo.xcprivacy não existe — o envio à App Store "
              "volta com ITMS-91053")
        return
    try:
        manifesto = MANIFESTO.read_text()
        xml.dom.minidom.parseString(manifesto)
    except Exception as erro:  # noqa: BLE001 — qualquer falha de leitura é falha
        falha(f"PrivacyInfo.xcprivacy não é um plist válido: {erro}")
        return

    # Duas cópias com o mesmo nome no pacote quebram o build ("Multiple
    # commands produce"); a do núcleo já vale para toda marca.
    for marca in marcas():
        if any((marca / "Resources").rglob("PrivacyInfo.xcprivacy")):
            falha(f"{marca.name}: tem PrivacyInfo.xcprivacy próprio — o do núcleo já entra "
                  "no pacote; junte as declarações lá")

    codigo = "\n".join(sem_comentarios(f.read_text()) for f in CORE.rglob("*.swift"))
    for categoria, padroes in APIS_DE_MOTIVO.items():
        usada = next((p for p in padroes if re.search(p, codigo)), None)
        declarada = f"<string>{categoria}</string>" in manifesto
        if usada and not declarada:
            falha(f"o código usa {usada.strip(chr(92) + 'b')} e o manifesto não declara {categoria}")
        elif declarada and not usada:
            aviso(f"o manifesto declara {categoria} e o código não usa mais — revise")


def main() -> None:
    for etapa in (checar_projeto, checar_formatos, checar_plists, checar_assets,
                  checar_brand_json, checar_vazamento, checar_localizacao,
                  checar_privacidade, checar_alvo_sem_ajustes):
        etapa()

    for a in avisos:
        print(f"aviso   {a}")
    for f in falhas:
        print(f"FALHA   {f}")

    print()
    print(f"{len(falhas)} falha(s), {len(avisos)} aviso(s)")
    sys.exit(1 if falhas else 0)


if __name__ == "__main__":
    main()
