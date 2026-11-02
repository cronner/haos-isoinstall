# Generates docs/<lang>.html: the same short guide in every language the wizard
# speaks. Run it from the repository root: python tools/guides.py
# English lives at docs/index.html (the hand-written page), so it is not emitted
# here; the language bar links to "./" for it.

import io
from pathlib import Path

LANGS = [
    ("en", "English", "./"),
    ("da", "Dansk", "da.html"),
    ("cs", "Čeština", "cs.html"),
    ("nl", "Nederlands", "nl.html"),
    ("fi", "Suomi", "fi.html"),
    ("fr", "Français", "fr.html"),
    ("de", "Deutsch", "de.html"),
    ("it", "Italiano", "it.html"),
    ("no", "Norsk", "no.html"),
    ("pl", "Polski", "pl.html"),
    ("pt", "Português", "pt.html"),
    ("ru", "Русский", "ru.html"),
    ("es", "Español", "es.html"),
    ("sv", "Svenska", "sv.html"),
]

T = {}

T["da"] = dict(
    title="Installer Home Assistant på en pc",
    h1="Installer Home Assistant på en pc",
    lede="Home Assistant styrer dit smarte hjem fra en computer i dit eget hus. "
         "Det virker, når internettet ikke gør, og dine data bliver hjemme.",
    lede2="Denne guide går fra download til første start. Du skal ikke kunne noget "
          "om Linux, og du kommer ikke til at skrive en kommando.",
    warn_t="Computerens disk bliver tømt helt.",
    warn_b="Alt på den slettes og kan ikke gendannes. Brug en pc du kan afse — "
           "aldrig din daglige maskine.",
    need_h="Det skal du bruge",
    need=[
        "En pc du kan afse (Intel eller AMD), som kan starte i UEFI-tilstand. Den bliver din Home Assistant-maskine.",
        "En USB-pind på 2 GB eller mere.",
        "Internet — medmindre du allerede har filen på en pind.",
        "Cirka en halv time. Det meste er ventetid.",
    ],
    steps_h="Trin for trin",
    steps=[
        ("Hent filen", "På releases-siden henter du den fil der ender på .iso (cirka 470 MB). "
                       "Du vælger ikke version: pinden henter selv den nyeste."),
        ("Skriv den til USB-pinden", "Brug Etcher: vælg filen, vælg pinden, tryk Flash. "
                                     "Træk ikke filen over på pinden som et billede."),
        ("Skift to indstillinger", "Tryk F2 eller Del ved opstart. Slå Secure Boot fra, "
                                   "og sæt SATA-tilstand til AHCI. Gem og luk."),
        ("Start fra pinden", "Lad pinden sidde og tænd pc'en. Starter den sit gamle system, "
                             "så tryk F12 og vælg USB-pinden."),
        ("Svar på spørgsmålene", "Sprog (14 mulige, tastaturet følger med), hvor filen skal "
                                 "komme fra, netværk, og hvilken disk der må slettes — skriv YES."),
        ("Vent, og tag pinden ud", "Den henter og tjekker filen, skriver den, og tilbyder "
                                   "til sidst at læse disken tilbage og sammenligne. Sig ja. "
                                   "Tag pinden ud når den siger det er færdigt."),
    ],
    first_h="Første start",
    first=[
        "Sæt pc'en til routeren med et kabel, og tænd den.",
        "Åbn http://homeassistant.local — “Preparing Home Assistant” kan tage tyve minutter.",
        "Lav din konto, og skriv adgangskoden ned: den kan ikke gendannes.",
    ],
    prob_h="Hvis det driller",
    prob=[
        ("Pc'en starter sit gamle system", "Genstart og tryk F12 for at vælge pinden. Står den ikke på listen, så skriv pinden igen med Etcher."),
        ("Skærmen er sort", "Se i indstillingerne at Secure Boot er slået fra, lad pinden sidde, og prøv igen."),
        ("Den finder ingen disk", "Lageret står sandsynligvis til RAID i stedet for AHCI. Skift det, og start igen."),
        ("Adressen åbner ikke", "Prøv http://homeassistant.local:8123, eller pc'ens adresse fra routeren med :8123 bagpå."),
    ],
    foot="Uofficielt projekt uden tilknytning til Open Home Foundation, Nabu Casa "
         "eller Home Assistant-projektet. Skrevet med AI-assistance, MIT-licens, "
         "ingen garanti og ingen support.",
    src="Kilde og udgivelser",
    manual="Teknisk manual",
)

T["de"] = dict(
    title="Home Assistant auf einem PC installieren",
    h1="Home Assistant auf einem PC installieren",
    lede="Home Assistant steuert dein Smart Home von einem Computer in deinem eigenen "
         "Haus. Es läuft weiter, wenn das Internet ausfällt, und deine Daten bleiben bei dir.",
    lede2="Diese Anleitung führt vom Download bis zum ersten Start. Du brauchst kein "
          "Linux-Wissen und musst keinen Befehl eintippen.",
    warn_t="Die Festplatte des Computers wird vollständig gelöscht.",
    warn_b="Alles darauf wird gelöscht und kann nicht wiederhergestellt werden. Nimm "
           "einen Rechner, den du entbehren kannst — nie deinen Alltags-PC.",
    need_h="Das brauchst du",
    need=[
        "Einen Rechner, den du entbehren kannst (Intel oder AMD), der im UEFI-Modus startet. Er wird deine Home-Assistant-Maschine.",
        "Einen USB-Stick mit 2 GB oder mehr.",
        "Internet — außer du hast die Datei schon auf einem Stick.",
        "Etwa eine halbe Stunde. Das meiste ist Warten.",
    ],
    steps_h="Schritt für Schritt",
    steps=[
        ("Datei herunterladen", "Auf der Releases-Seite lädst du die Datei, die auf .iso endet "
                                "(etwa 470 MB). Du wählst keine Version: der Stick holt selbst die neueste."),
        ("Auf den USB-Stick schreiben", "Nimm Etcher: Datei wählen, Stick wählen, Flash drücken. "
                                        "Zieh die Datei nicht wie ein Bild auf den Stick."),
        ("Zwei Einstellungen ändern", "Beim Start F2 oder Entf drücken. Secure Boot ausschalten "
                                      "und den SATA-Modus auf AHCI stellen. Speichern und beenden."),
        ("Vom Stick starten", "Stick stecken lassen und den PC einschalten. Startet er sein altes "
                              "System, drücke F12 und wähle den USB-Stick."),
        ("Die Fragen beantworten", "Sprache (14 möglich, die Tastatur folgt), woher die Datei "
                                   "kommen soll, Netzwerk und welche Platte gelöscht werden darf — YES eintippen."),
        ("Warten, dann Stick abziehen", "Er lädt und prüft die Datei, schreibt sie und bietet am Ende "
                                        "an, die Platte zurückzulesen und zu vergleichen. Sag ja. "
                                        "Zieh den Stick ab, wenn er fertig meldet."),
    ],
    first_h="Erster Start",
    first=[
        "Verbinde den PC mit einem Kabel am Router und schalte ihn ein.",
        "Öffne http://homeassistant.local — „Preparing Home Assistant“ kann zwanzig Minuten dauern.",
        "Erstelle dein Konto und schreib das Passwort auf: es lässt sich nicht wiederherstellen.",
    ],
    prob_h="Wenn etwas klemmt",
    prob=[
        ("Der PC startet sein altes System", "Neu starten, F12 drücken und den Stick wählen. Steht er nicht in der Liste, schreib den Stick mit Etcher neu."),
        ("Der Bildschirm bleibt schwarz", "Prüfe in den Einstellungen, dass Secure Boot aus ist, lass den Stick stecken und versuch es erneut."),
        ("Es wird keine Platte gefunden", "Der Speicher steht vermutlich auf RAID statt AHCI. Ändere das und starte neu."),
        ("Die Adresse öffnet nicht", "Probiere http://homeassistant.local:8123, oder die Adresse des PCs aus dem Router mit :8123."),
    ],
    foot="Inoffizielles Projekt, nicht verbunden mit der Open Home Foundation, Nabu "
         "Casa oder dem Home-Assistant-Projekt. Mit KI-Unterstützung geschrieben, "
         "MIT-Lizenz, keine Garantie und kein Support.",
    src="Quellcode und Releases",
    manual="Technisches Handbuch",
)

T["fr"] = dict(
    title="Installer Home Assistant sur un PC",
    h1="Installer Home Assistant sur un PC",
    lede="Home Assistant pilote votre maison connectée depuis un ordinateur chez vous. "
         "Il continue de fonctionner quand Internet tombe, et vos données restent chez vous.",
    lede2="Ce guide va du téléchargement au premier démarrage. Aucune connaissance de "
          "Linux, aucune commande à taper.",
    warn_t="Le disque de l'ordinateur est effacé entièrement.",
    warn_b="Tout ce qu'il contient est perdu et ne peut pas être récupéré. Utilisez un "
           "ordinateur dont vous pouvez vous passer — jamais votre machine du quotidien.",
    need_h="Ce qu'il vous faut",
    need=[
        "Un ordinateur dont vous pouvez vous passer (Intel ou AMD), qui démarre en mode UEFI. Il deviendra votre machine Home Assistant.",
        "Une clé USB de 2 Go ou plus.",
        "Internet — sauf si vous avez déjà le fichier sur une clé.",
        "Environ une demi-heure. L'essentiel est de l'attente.",
    ],
    steps_h="Étape par étape",
    steps=[
        ("Télécharger le fichier", "Sur la page des versions, prenez le fichier qui finit par .iso "
                                   "(environ 470 Mo). Vous ne choisissez pas de version : la clé récupère la plus récente."),
        ("L'écrire sur la clé USB", "Utilisez Etcher : choisissez le fichier, la clé, puis Flash. "
                                    "Ne faites pas glisser le fichier sur la clé comme une photo."),
        ("Changer deux réglages", "Appuyez sur F2 ou Suppr au démarrage. Désactivez Secure Boot "
                                  "et mettez le mode SATA sur AHCI. Enregistrez et quittez."),
        ("Démarrer sur la clé", "Laissez la clé en place et allumez le PC. S'il démarre son ancien "
                                "système, appuyez sur F12 et choisissez la clé USB."),
        ("Répondre aux questions", "Langue (14 possibles, le clavier suit), l'origine du fichier, "
                                   "le réseau, et le disque à effacer — tapez YES pour confirmer."),
        ("Attendre, puis retirer la clé", "Il télécharge et vérifie le fichier, l'écrit, puis propose "
                                          "de relire le disque pour comparer. Dites oui. Retirez la clé "
                                          "quand il annonce la fin."),
    ],
    first_h="Premier démarrage",
    first=[
        "Reliez le PC au routeur avec un câble, et allumez-le.",
        "Ouvrez http://homeassistant.local — « Preparing Home Assistant » peut prendre vingt minutes.",
        "Créez votre compte et notez le mot de passe : il n'est pas récupérable.",
    ],
    prob_h="Si ça coince",
    prob=[
        ("Le PC démarre son ancien système", "Redémarrez, appuyez sur F12 et choisissez la clé. Si elle n'apparaît pas, réécrivez-la avec Etcher."),
        ("L'écran reste noir", "Vérifiez dans les réglages que Secure Boot est désactivé, laissez la clé en place et réessayez."),
        ("Aucun disque n'est trouvé", "Le stockage est probablement en RAID au lieu d'AHCI. Changez-le et recommencez."),
        ("L'adresse ne s'ouvre pas", "Essayez http://homeassistant.local:8123, ou l'adresse du PC vue par le routeur avec :8123."),
    ],
    foot="Projet non officiel, sans lien avec l'Open Home Foundation, Nabu Casa ou le "
         "projet Home Assistant. Écrit avec l'aide d'une IA, licence MIT, sans "
         "garantie ni support.",
    src="Code et versions",
    manual="Manuel technique",
)

T["es"] = dict(
    title="Instalar Home Assistant en un PC",
    h1="Instalar Home Assistant en un PC",
    lede="Home Assistant controla tu casa conectada desde un ordenador en tu propia casa. "
         "Sigue funcionando cuando no hay internet, y tus datos se quedan contigo.",
    lede2="Esta guía va de la descarga al primer arranque. No hace falta saber Linux ni "
          "escribir ningún comando.",
    warn_t="El disco del ordenador se borra por completo.",
    warn_b="Todo lo que contiene se pierde y no se puede recuperar. Usa un ordenador del "
           "que puedas prescindir — nunca el de cada día.",
    need_h="Lo que necesitas",
    need=[
        "Un ordenador del que puedas prescindir (Intel o AMD) que arranque en modo UEFI. Será tu máquina de Home Assistant.",
        "Un lápiz USB de 2 GB o más.",
        "Internet — salvo que ya tengas el archivo en un lápiz.",
        "Unos treinta minutos. Casi todo es esperar.",
    ],
    steps_h="Paso a paso",
    steps=[
        ("Descargar el archivo", "En la página de versiones, coge el archivo que termina en .iso "
                                 "(unos 470 MB). No eliges versión: el lápiz trae la más reciente."),
        ("Escribirlo en el lápiz USB", "Usa Etcher: elige el archivo, el lápiz y pulsa Flash. "
                                       "No arrastres el archivo al lápiz como una foto."),
        ("Cambiar dos ajustes", "Pulsa F2 o Supr al arrancar. Desactiva Secure Boot y pon el modo "
                                "SATA en AHCI. Guarda y sal."),
        ("Arrancar desde el lápiz", "Deja el lápiz puesto y enciende el PC. Si arranca su sistema "
                                    "antiguo, pulsa F12 y elige el lápiz USB."),
        ("Responder a las preguntas", "Idioma (14 posibles, el teclado se ajusta solo), de dónde "
                                      "viene el archivo, la red y qué disco se puede borrar — escribe YES."),
        ("Esperar y quitar el lápiz", "Descarga y comprueba el archivo, lo escribe y al final ofrece "
                                      "leer el disco y compararlo. Di que sí. Quita el lápiz cuando "
                                      "avise de que ha terminado."),
    ],
    first_h="Primer arranque",
    first=[
        "Conecta el PC al router con un cable y enciéndelo.",
        "Abre http://homeassistant.local — «Preparing Home Assistant» puede tardar veinte minutos.",
        "Crea tu cuenta y apunta la contraseña: no se puede recuperar.",
    ],
    prob_h="Si algo falla",
    prob=[
        ("El PC arranca su sistema antiguo", "Reinicia, pulsa F12 y elige el lápiz. Si no aparece, vuelve a escribirlo con Etcher."),
        ("La pantalla se queda negra", "Comprueba en los ajustes que Secure Boot está desactivado, deja el lápiz puesto y prueba otra vez."),
        ("No encuentra ningún disco", "El almacenamiento estará en RAID en vez de AHCI. Cámbialo y vuelve a empezar."),
        ("La dirección no abre", "Prueba http://homeassistant.local:8123, o la dirección del PC en el router con :8123."),
    ],
    foot="Proyecto no oficial, sin relación con Open Home Foundation, Nabu Casa ni el "
         "proyecto Home Assistant. Escrito con ayuda de IA, licencia MIT, sin garantía "
         "ni soporte.",
    src="Código y versiones",
    manual="Manual técnico",
)

T["it"] = dict(
    title="Installare Home Assistant su un PC",
    h1="Installare Home Assistant su un PC",
    lede="Home Assistant gestisce la tua casa intelligente da un computer in casa tua. "
         "Continua a funzionare quando internet non c'e, e i tuoi dati restano tuoi.",
    lede2="Questa guida va dal download al primo avvio. Non serve sapere Linux e non devi "
          "digitare nessun comando.",
    warn_t="Il disco del computer viene cancellato completamente.",
    warn_b="Tutto quello che contiene va perso e non si recupera. Usa un computer di cui "
           "puoi fare a meno, mai quello di tutti i giorni.",
    need_h="Cosa ti serve",
    need=[
        "Un computer di cui puoi fare a meno (Intel o AMD) che si avvii in modalita UEFI. Diventera la tua macchina Home Assistant.",
        "Una chiavetta USB da 2 GB o piu.",
        "Internet, a meno che tu non abbia gia il file su una chiavetta.",
        "Circa mezz'ora. La maggior parte e attesa.",
    ],
    steps_h="Passo per passo",
    steps=[
        ("Scaricare il file", "Nella pagina delle versioni prendi il file che finisce in .iso "
                              "(circa 470 MB). Non scegli la versione: la chiavetta prende la piu recente."),
        ("Scriverlo sulla chiavetta", "Usa Etcher: scegli il file, la chiavetta, premi Flash. "
                                      "Non trascinare il file sulla chiavetta come una foto."),
        ("Cambiare due impostazioni", "All'avvio premi F2 o Canc. Disattiva Secure Boot e metti "
                                      "la modalita SATA su AHCI. Salva ed esci."),
        ("Avviare dalla chiavetta", "Lascia la chiavetta inserita e accendi il PC. Se parte il "
                                    "vecchio sistema, premi F12 e scegli la chiavetta USB."),
        ("Rispondere alle domande", "Lingua (14 disponibili, la tastiera si imposta da sola), da dove "
                                    "arriva il file, la rete e quale disco si puo cancellare: scrivi YES."),
        ("Aspettare e togliere la chiavetta", "Scarica e controlla il file, lo scrive e alla fine "
                                              "propone di rileggere il disco e confrontarlo. Di si. "
                                              "Togli la chiavetta quando dice che ha finito."),
    ],
    first_h="Primo avvio",
    first=[
        "Collega il PC al router con un cavo e accendilo.",
        "Apri http://homeassistant.local: \"Preparing Home Assistant\" puo richiedere venti minuti.",
        "Crea il tuo account e annota la password: non si puo recuperare.",
    ],
    prob_h="Se qualcosa non va",
    prob=[
        ("Il PC avvia il vecchio sistema", "Riavvia, premi F12 e scegli la chiavetta. Se non compare, riscrivila con Etcher."),
        ("Lo schermo resta nero", "Controlla nelle impostazioni che Secure Boot sia disattivato, lascia la chiavetta e riprova."),
        ("Non trova nessun disco", "Lo storage e probabilmente in RAID invece di AHCI. Cambialo e riparti."),
        ("L'indirizzo non si apre", "Prova http://homeassistant.local:8123, oppure l'indirizzo del PC visto dal router con :8123."),
    ],
    foot="Progetto non ufficiale, senza legami con Open Home Foundation, Nabu Casa o il "
         "progetto Home Assistant. Scritto con l'aiuto di un'IA, licenza MIT, nessuna "
         "garanzia e nessun supporto.",
    src="Codice e versioni",
    manual="Manuale tecnico",
)

T["nl"] = dict(
    title="Home Assistant op een pc installeren",
    h1="Home Assistant op een pc installeren",
    lede="Home Assistant bestuurt je slimme huis vanaf een computer in je eigen huis. Het "
         "blijft werken als internet uitvalt, en je gegevens blijven bij jou.",
    lede2="Deze gids loopt van het downloaden tot de eerste start. Je hoeft niets van Linux "
          "te weten en hoeft geen commando te typen.",
    warn_t="De schijf van de computer wordt volledig gewist.",
    warn_b="Alles erop wordt verwijderd en kan niet worden teruggehaald. Gebruik een pc die "
           "je kunt missen — nooit je dagelijkse machine.",
    need_h="Wat je nodig hebt",
    need=[
        "Een pc die je kunt missen (Intel of AMD) die in UEFI-modus start. Die wordt je Home Assistant-machine.",
        "Een USB-stick van 2 GB of meer.",
        "Internet — tenzij je het bestand al op een stick hebt.",
        "Ongeveer een half uur. Het meeste is wachten.",
    ],
    steps_h="Stap voor stap",
    steps=[
        ("Het bestand downloaden", "Op de releases-pagina neem je het bestand dat op .iso eindigt "
                                   "(ongeveer 470 MB). Je kiest geen versie: de stick haalt zelf de nieuwste."),
        ("Naar de USB-stick schrijven", "Gebruik Etcher: kies het bestand, de stick, druk op Flash. "
                                        "Sleep het bestand niet als een foto naar de stick."),
        ("Twee instellingen aanpassen", "Druk bij het starten op F2 of Del. Zet Secure Boot uit en "
                                        "zet de SATA-modus op AHCI. Opslaan en afsluiten."),
        ("Vanaf de stick starten", "Laat de stick zitten en zet de pc aan. Start hij zijn oude "
                                   "systeem, druk dan op F12 en kies de USB-stick."),
        ("De vragen beantwoorden", "Taal (14 mogelijk, het toetsenbord volgt), waar het bestand "
                                   "vandaan komt, het netwerk en welke schijf gewist mag worden — typ YES."),
        ("Wachten en de stick eruit halen", "Hij haalt het bestand op, controleert het, schrijft het en "
                                            "biedt aan het slot aan de schijf terug te lezen en te vergelijken. "
                                            "Zeg ja. Haal de stick eruit als hij klaar meldt."),
    ],
    first_h="Eerste start",
    first=[
        "Sluit de pc met een kabel op de router aan en zet hem aan.",
        "Open http://homeassistant.local — “Preparing Home Assistant” kan twintig minuten duren.",
        "Maak je account en schrijf het wachtwoord op: het is niet te herstellen.",
    ],
    prob_h="Als het niet lukt",
    prob=[
        ("De pc start zijn oude systeem", "Herstart, druk op F12 en kies de stick. Staat hij er niet bij, schrijf de stick dan opnieuw met Etcher."),
        ("Het scherm blijft zwart", "Controleer in de instellingen dat Secure Boot uit staat, laat de stick zitten en probeer opnieuw."),
        ("Er wordt geen schijf gevonden", "De opslag staat waarschijnlijk op RAID in plaats van AHCI. Zet dat om en start opnieuw."),
        ("Het adres opent niet", "Probeer http://homeassistant.local:8123, of het adres van de pc uit de router met :8123."),
    ],
    foot="Onofficieel project, niet verbonden aan de Open Home Foundation, Nabu Casa of "
         "het Home Assistant-project. Geschreven met hulp van AI, MIT-licentie, geen "
         "garantie en geen ondersteuning.",
    src="Broncode en releases",
    manual="Technische handleiding",
)

T["sv"] = dict(
    title="Installera Home Assistant på en PC",
    h1="Installera Home Assistant på en PC",
    lede="Home Assistant styr ditt smarta hem från en dator i ditt eget hus. Det fortsätter "
         "fungera när internet inte gör det, och dina data stannar hos dig.",
    lede2="Den här guiden går från nedladdning till första start. Du behöver inte kunna något "
          "om Linux och skriver inga kommandon.",
    warn_t="Datorns disk töms helt.",
    warn_b="Allt på den raderas och går inte att få tillbaka. Använd en dator du kan avvara — "
           "aldrig din vanliga maskin.",
    need_h="Det här behöver du",
    need=[
        "En dator du kan avvara (Intel eller AMD) som startar i UEFI-läge. Den blir din Home Assistant-maskin.",
        "Ett USB-minne på 2 GB eller mer.",
        "Internet — om du inte redan har filen på ett minne.",
        "Ungefär en halvtimme. Det mesta är väntan.",
    ],
    steps_h="Steg för steg",
    steps=[
        ("Ladda ner filen", "På releases-sidan tar du filen som slutar på .iso (cirka 470 MB). "
                            "Du väljer ingen version: minnet hämtar den senaste själv."),
        ("Skriv den till USB-minnet", "Använd Etcher: välj filen, välj minnet, tryck Flash. "
                                      "Dra inte filen till minnet som en bild."),
        ("Ändra två inställningar", "Tryck F2 eller Del vid start. Stäng av Secure Boot och sätt "
                                    "SATA-läget till AHCI. Spara och avsluta."),
        ("Starta från minnet", "Låt minnet sitta kvar och slå på datorn. Startar den sitt gamla "
                               "system, tryck F12 och välj USB-minnet."),
        ("Svara på frågorna", "Språk (14 möjliga, tangentbordet följer med), var filen ska komma "
                              "ifrån, nätverket och vilken disk som får raderas — skriv YES."),
        ("Vänta och ta ut minnet", "Den hämtar och kontrollerar filen, skriver den och erbjuder "
                                   "till slut att läsa tillbaka disken och jämföra. Säg ja. Ta ut "
                                   "minnet när den säger att den är klar."),
    ],
    first_h="Första starten",
    first=[
        "Anslut datorn till routern med en kabel och slå på den.",
        "Öppna http://homeassistant.local — ”Preparing Home Assistant” kan ta tjugo minuter.",
        "Skapa ditt konto och skriv ner lösenordet: det går inte att återställa.",
    ],
    prob_h="Om något strular",
    prob=[
        ("Datorn startar sitt gamla system", "Starta om, tryck F12 och välj minnet. Finns det inte med, skriv det igen med Etcher."),
        ("Skärmen är svart", "Kontrollera i inställningarna att Secure Boot är av, låt minnet sitta och försök igen."),
        ("Den hittar ingen disk", "Lagringen står troligen på RAID i stället för AHCI. Ändra det och starta igen."),
        ("Adressen öppnas inte", "Prova http://homeassistant.local:8123, eller datorns adress från routern med :8123."),
    ],
    foot="Inofficiellt projekt, utan koppling till Open Home Foundation, Nabu Casa eller "
         "Home Assistant-projektet. Skrivet med AI-hjälp, MIT-licens, ingen garanti och "
         "ingen support.",
    src="Källkod och utgåvor",
    manual="Teknisk manual",
)

T["no"] = dict(
    title="Installer Home Assistant på en PC",
    h1="Installer Home Assistant på en PC",
    lede="Home Assistant styrer det smarte hjemmet ditt fra en datamaskin i ditt eget hus. "
         "Det virker når internettet ikke gjør det, og dataene blir hos deg.",
    lede2="Denne guiden går fra nedlasting til første oppstart. Du trenger ikke kunne noe om "
          "Linux, og du skriver ingen kommandoer.",
    warn_t="Datamaskinens disk blir tømt helt.",
    warn_b="Alt på den slettes og kan ikke gjenskapes. Bruk en maskin du kan avse — aldri "
           "den du bruker til daglig.",
    need_h="Dette trenger du",
    need=[
        "En maskin du kan avse (Intel eller AMD) som starter i UEFI-modus. Den blir din Home Assistant-maskin.",
        "En USB-pinne på 2 GB eller mer.",
        "Internett — med mindre du allerede har filen på en pinne.",
        "Omtrent en halvtime. Det meste er venting.",
    ],
    steps_h="Steg for steg",
    steps=[
        ("Last ned filen", "På releases-siden tar du filen som slutter på .iso (cirka 470 MB). "
                           "Du velger ingen versjon: pinnen henter den nyeste selv."),
        ("Skriv den til USB-pinnen", "Bruk Etcher: velg filen, velg pinnen, trykk Flash. "
                                     "Ikke dra filen over på pinnen som et bilde."),
        ("Endre to innstillinger", "Trykk F2 eller Del ved oppstart. Slå av Secure Boot og sett "
                                   "SATA-modus til AHCI. Lagre og avslutt."),
        ("Start fra pinnen", "La pinnen sitte og slå på maskinen. Starter den sitt gamle system, "
                             "trykk F12 og velg USB-pinnen."),
        ("Svar på spørsmålene", "Språk (14 mulige, tastaturet følger med), hvor filen skal komme "
                                "fra, nettverket og hvilken disk som kan slettes — skriv YES."),
        ("Vent, og ta ut pinnen", "Den henter og sjekker filen, skriver den, og tilbyr til slutt "
                                  "å lese disken tilbake og sammenligne. Si ja. Ta ut pinnen når "
                                  "den sier den er ferdig."),
    ],
    first_h="Første oppstart",
    first=[
        "Koble maskinen til ruteren med en kabel, og slå den på.",
        "Åpne http://homeassistant.local — «Preparing Home Assistant» kan ta tjue minutter.",
        "Lag kontoen din, og skriv ned passordet: det kan ikke gjenopprettes.",
    ],
    prob_h="Hvis noe krangler",
    prob=[
        ("Maskinen starter sitt gamle system", "Start på nytt, trykk F12 og velg pinnen. Står den ikke i listen, skriv den på nytt med Etcher."),
        ("Skjermen er svart", "Sjekk i innstillingene at Secure Boot er slått av, la pinnen sitte og prøv igjen."),
        ("Den finner ingen disk", "Lagringen står trolig på RAID i stedet for AHCI. Endre det og start på nytt."),
        ("Adressen åpner ikke", "Prøv http://homeassistant.local:8123, eller maskinens adresse fra ruteren med :8123."),
    ],
    foot="Uoffisielt prosjekt, uten tilknytning til Open Home Foundation, Nabu Casa eller "
         "Home Assistant-prosjektet. Skrevet med AI-hjelp, MIT-lisens, ingen garanti og "
         "ingen støtte.",
    src="Kildekode og utgivelser",
    manual="Teknisk manual",
)

T["fi"] = dict(
    title="Asenna Home Assistant tietokoneelle",
    h1="Asenna Home Assistant tietokoneelle",
    lede="Home Assistant ohjaa älykotiasi omassa kodissasi olevasta tietokoneesta. Se toimii "
         "silloinkin kun internet ei toimi, ja tietosi pysyvät sinulla.",
    lede2="Tämä opas vie latauksesta ensimmäiseen käynnistykseen. Sinun ei tarvitse osata "
          "Linuxia eikä kirjoittaa komentoja.",
    warn_t="Tietokoneen levy tyhjennetään kokonaan.",
    warn_b="Kaikki sillä oleva poistuu eikä palaudu. Käytä konetta, josta voit luopua — älä "
           "koskaan jokapäiväistä konettasi.",
    need_h="Tarvitset",
    need=[
        "Koneen, josta voit luopua (Intel tai AMD), joka käynnistyy UEFI-tilassa. Siitä tulee Home Assistant -koneesi.",
        "USB-muistin, 2 GB tai enemmän.",
        "Internetin — paitsi jos tiedosto on jo muistilla.",
        "Noin puoli tuntia. Suurin osa on odottamista.",
    ],
    steps_h="Askel askeleelta",
    steps=[
        ("Lataa tiedosto", "Ota julkaisusivulta tiedosto, joka päättyy .iso (noin 470 MB). Et valitse "
                           "versiota: muisti hakee itse uusimman."),
        ("Kirjoita se USB-muistille", "Käytä Etcheriä: valitse tiedosto, valitse muisti, paina Flash. "
                                      "Älä vedä tiedostoa muistille kuin kuvaa."),
        ("Muuta kahta asetusta", "Paina käynnistyksen yhteydessä F2 tai Del. Kytke Secure Boot pois "
                                 "ja aseta SATA-tilaksi AHCI. Tallenna ja poistu."),
        ("Käynnistä muistilta", "Jätä muisti paikalleen ja käynnistä kone. Jos se käynnistää vanhan "
                                "järjestelmän, paina F12 ja valitse USB-muisti."),
        ("Vastaa kysymyksiin", "Kieli (14 vaihtoehtoa, näppäimistö seuraa mukana), mistä tiedosto "
                               "tulee, verkko ja mikä levy saa tyhjentyä — kirjoita YES."),
        ("Odota ja ota muisti pois", "Se hakee ja tarkistaa tiedoston, kirjoittaa sen ja tarjoaa lopuksi "
                                     "lukea levyn takaisin ja vertailla. Sano kyllä. Ota muisti pois, "
                                     "kun se ilmoittaa olevansa valmis."),
    ],
    first_h="Ensimmäinen käynnistys",
    first=[
        "Yhdistä kone reitittimeen kaapelilla ja käynnistä se.",
        "Avaa http://homeassistant.local — ”Preparing Home Assistant” voi kestää kaksikymmentä minuuttia.",
        "Luo tunnuksesi ja kirjoita salasana muistiin: sitä ei voi palauttaa.",
    ],
    prob_h="Jos jokin takkuaa",
    prob=[
        ("Kone käynnistää vanhan järjestelmän", "Käynnistä uudelleen, paina F12 ja valitse muisti. Jos se ei ole listalla, kirjoita muisti uudelleen Etcherillä."),
        ("Näyttö on musta", "Tarkista asetuksista, että Secure Boot on pois, jätä muisti paikalleen ja yritä uudelleen."),
        ("Se ei löydä levyä", "Tallennus on luultavasti RAID-tilassa AHCI:n sijaan. Vaihda se ja käynnistä uudelleen."),
        ("Osoite ei avaudu", "Kokeile http://homeassistant.local:8123 tai koneen osoitetta reitittimestä :8123-lisällä."),
    ],
    foot="Epävirallinen projekti, ei sidoksissa Open Home Foundationiin, Nabu Casaan tai "
         "Home Assistant -projektiin. Kirjoitettu tekoälyn avustuksella, MIT-lisenssi, "
         "ei takuuta eikä tukea.",
    src="Lähdekoodi ja julkaisut",
    manual="Tekninen käsikirja",
)

T["pl"] = dict(
    title="Zainstaluj Home Assistant na komputerze",
    h1="Zainstaluj Home Assistant na komputerze",
    lede="Home Assistant steruje inteligentnym domem z komputera w twoim własnym domu. Działa, "
         "gdy internet nie działa, a twoje dane zostają u ciebie.",
    lede2="Ten przewodnik prowadzi od pobrania do pierwszego uruchomienia. Nie musisz znać "
          "Linuxa ani wpisywać żadnych poleceń.",
    warn_t="Dysk komputera zostanie całkowicie wyczyszczony.",
    warn_b="Wszystko na nim przepada i nie da się tego odzyskać. Użyj komputera, którego możesz "
           "się pozbyć — nigdy swojego codziennego.",
    need_h="Czego potrzebujesz",
    need=[
        "Komputera, którego możesz się pozbyć (Intel lub AMD), startującego w trybie UEFI. Zostanie twoją maszyną Home Assistant.",
        "Pendrive'a 2 GB lub większego.",
        "Internetu — chyba że plik masz już na pendrive.",
        "Około pół godziny. Większość to czekanie.",
    ],
    steps_h="Krok po kroku",
    steps=[
        ("Pobierz plik", "Na stronie wydań weź plik kończący się na .iso (około 470 MB). Nie wybierasz "
                         "wersji: pendrive sam pobierze najnowszą."),
        ("Zapisz go na pendrive", "Użyj Etchera: wybierz plik, wybierz pendrive, naciśnij Flash. "
                                  "Nie przeciągaj pliku na pendrive jak zdjęcia."),
        ("Zmień dwa ustawienia", "Przy starcie naciśnij F2 lub Del. Wyłącz Secure Boot i ustaw tryb "
                                 "SATA na AHCI. Zapisz i wyjdź."),
        ("Uruchom z pendrive", "Zostaw pendrive i włącz komputer. Jeśli uruchomi stary system, "
                               "naciśnij F12 i wybierz pendrive."),
        ("Odpowiedz na pytania", "Język (14 możliwości, klawiatura sama się ustawi), skąd ma pochodzić "
                                 "plik, sieć i który dysk można usunąć — wpisz YES."),
        ("Poczekaj i wyjmij pendrive", "Pobiera i sprawdza plik, zapisuje go, a na końcu proponuje "
                                       "odczytać dysk i porównać. Powiedz tak. Wyjmij pendrive, gdy "
                                       "zgłosi, że skończył."),
    ],
    first_h="Pierwsze uruchomienie",
    first=[
        "Podłącz komputer kablem do routera i włącz go.",
        "Otwórz http://homeassistant.local — „Preparing Home Assistant” może potrwać dwadzieścia minut.",
        "Załóż konto i zapisz hasło: nie da się go odzyskać.",
    ],
    prob_h="Jeśli coś nie działa",
    prob=[
        ("Komputer uruchamia stary system", "Zrestartuj, naciśnij F12 i wybierz pendrive. Jeśli go nie ma na liście, zapisz go ponownie Etcherem."),
        ("Ekran pozostaje czarny", "Sprawdź w ustawieniach, czy Secure Boot jest wyłączony, zostaw pendrive i spróbuj ponownie."),
        ("Nie znajduje żadnego dysku", "Dysk jest prawdopodobnie w trybie RAID zamiast AHCI. Zmień to i zacznij od nowa."),
        ("Adres się nie otwiera", "Spróbuj http://homeassistant.local:8123 albo adresu komputera z routera z :8123."),
    ],
    foot="Projekt nieoficjalny, niezwiązany z Open Home Foundation, Nabu Casa ani projektem "
         "Home Assistant. Napisany z pomocą AI, licencja MIT, bez gwarancji i wsparcia.",
    src="Kod i wydania",
    manual="Instrukcja techniczna",
)

T["pt"] = dict(
    title="Instalar o Home Assistant num PC",
    h1="Instalar o Home Assistant num PC",
    lede="O Home Assistant controla a tua casa inteligente a partir de um computador na tua "
         "própria casa. Continua a funcionar sem internet, e os teus dados ficam contigo.",
    lede2="Este guia vai do download ao primeiro arranque. Não precisas de saber Linux nem "
          "de escrever comandos.",
    warn_t="O disco do computador é apagado por completo.",
    warn_b="Tudo o que tem lá se perde e não volta. Usa um computador de que possas prescindir — "
           "nunca o do dia a dia.",
    need_h="Do que precisas",
    need=[
        "Um computador de que possas prescindir (Intel ou AMD) que arranque em modo UEFI. Passa a ser a tua máquina de Home Assistant.",
        "Uma pen USB de 2 GB ou mais.",
        "Internet — a não ser que já tenhas o ficheiro numa pen.",
        "Cerca de meia hora. A maior parte é esperar.",
    ],
    steps_h="Passo a passo",
    steps=[
        ("Transfere o ficheiro", "Na página das versões, escolhe o ficheiro que acaba em .iso "
                                 "(cerca de 470 MB). Não escolhes versão: a pen vai buscar a mais recente."),
        ("Grava-o na pen USB", "Usa o Etcher: escolhe o ficheiro, a pen, e carrega em Flash. "
                               "Não arrastes o ficheiro para a pen como uma fotografia."),
        ("Muda dois ajustes", "Carrega em F2 ou Del ao arrancar. Desliga o Secure Boot e põe o modo "
                              "SATA em AHCI. Guarda e sai."),
        ("Arranca pela pen", "Deixa a pen e liga o PC. Se arrancar o sistema antigo, carrega em F12 "
                             "e escolhe a pen USB."),
        ("Responde às perguntas", "Idioma (14 disponíveis, o teclado vem junto), de onde vem o "
                                  "ficheiro, a rede, e que disco pode ser apagado — escreve YES."),
        ("Espera e tira a pen", "Transfere e verifica o ficheiro, grava-o e no fim propõe ler o disco "
                                "e comparar. Diz que sim. Tira a pen quando avisar que terminou."),
    ],
    first_h="Primeiro arranque",
    first=[
        "Liga o PC ao router com um cabo e liga-o.",
        "Abre http://homeassistant.local — o “Preparing Home Assistant” pode demorar vinte minutos.",
        "Cria a tua conta e aponta a palavra-passe: não é recuperável.",
    ],
    prob_h="Se algo falhar",
    prob=[
        ("O PC arranca o sistema antigo", "Reinicia, carrega em F12 e escolhe a pen. Se não aparecer, grava-a outra vez com o Etcher."),
        ("O ecrã fica preto", "Vê nos ajustes se o Secure Boot está desligado, deixa a pen e tenta outra vez."),
        ("Não encontra nenhum disco", "O armazenamento está provavelmente em RAID em vez de AHCI. Muda e recomeça."),
        ("O endereço não abre", "Tenta http://homeassistant.local:8123, ou o endereço do PC no router com :8123."),
    ],
    foot="Projeto não oficial, sem ligação à Open Home Foundation, à Nabu Casa ou ao projeto "
         "Home Assistant. Escrito com ajuda de IA, licença MIT, sem garantia nem suporte.",
    src="Código e versões",
    manual="Manual técnico",
)

T["cs"] = dict(
    title="Instalace Home Assistant na počítač",
    h1="Instalace Home Assistant na počítač",
    lede="Home Assistant řídí vaši chytrou domácnost z počítače u vás doma. Funguje i tehdy, "
         "když internet nefunguje, a vaše data zůstávají u vás.",
    lede2="Tento návod vede od stažení k prvnímu spuštění. Nemusíte umět Linux ani psát žádné příkazy.",
    warn_t="Disk počítače bude zcela vymazán.",
    warn_b="Všechno na něm se nenávratně ztratí. Použijte počítač, který můžete oželet — nikdy "
           "ten, který používáte denně.",
    need_h="Co budete potřebovat",
    need=[
        "Počítač, který můžete oželet (Intel nebo AMD), schopný startu v režimu UEFI. Stane se vaším strojem s Home Assistantem.",
        "USB flash disk s kapacitou 2 GB a více.",
        "Internet — pokud už soubor nemáte na flash disku.",
        "Asi půl hodiny. Většinu času se čeká.",
    ],
    steps_h="Krok za krokem",
    steps=[
        ("Stáhněte soubor", "Na stránce vydání vezměte soubor končící na .iso (asi 470 MB). "
                            "Verzi nevybíráte: flash disk si stáhne tu nejnovější sám."),
        ("Zapište ho na USB flash disk", "Použijte Etcher: vyberte soubor, vyberte disk a stiskněte Flash. "
                                         "Nepřetahujte soubor na disk jako fotografii."),
        ("Změňte dvě nastavení", "Při startu stiskněte F2 nebo Del. Vypněte Secure Boot a nastavte "
                                 "režim SATA na AHCI. Uložte a ukončete."),
        ("Spusťte z flash disku", "Nechte disk zastrčený a zapněte počítač. Pokud naběhne starý "
                                  "systém, stiskněte F12 a vyberte USB flash disk."),
        ("Odpovězte na otázky", "Jazyk (14 možností, klávesnice se nastaví sama), odkud má soubor "
                                "přijít, síť a který disk se smí vymazat — napište YES."),
        ("Počkejte a vyjměte disk", "Stáhne a zkontroluje soubor, zapíše ho a nakonec nabídne "
                                    "přečíst disk zpět a porovnat. Řekněte ano. Vyjměte disk, až "
                                    "oznámí, že je hotovo."),
    ],
    first_h="První spuštění",
    first=[
        "Připojte počítač kabelem k routeru a zapněte ho.",
        "Otevřete http://homeassistant.local — „Preparing Home Assistant“ může trvat dvacet minut.",
        "Vytvořte účet a poznamenejte si heslo: nelze ho obnovit.",
    ],
    prob_h="Když se něco nedaří",
    prob=[
        ("Počítač spouští starý systém", "Restartujte, stiskněte F12 a vyberte flash disk. Pokud v seznamu není, zapište ho znovu v Etcheru."),
        ("Obrazovka zůstává černá", "Zkontrolujte v nastavení, že je Secure Boot vypnutý, nechte disk zastrčený a zkuste to znovu."),
        ("Nenajde žádný disk", "Úložiště je pravděpodobně v režimu RAID místo AHCI. Změňte to a začněte znovu."),
        ("Adresa se neotevírá", "Zkuste http://homeassistant.local:8123, nebo adresu počítače z routeru s :8123."),
    ],
    foot="Neoficiální projekt, bez spojení s Open Home Foundation, Nabu Casa nebo projektem "
         "Home Assistant. Napsáno s pomocí AI, licence MIT, bez záruky a bez podpory.",
    src="Zdrojový kód a vydání",
    manual="Technický manuál",
)

T["ru"] = dict(
    title="Установка Home Assistant на ПК",
    h1="Установка Home Assistant на ПК",
    lede="Home Assistant управляет умным домом с компьютера у вас дома. Он работает, даже "
         "когда интернета нет, а ваши данные остаются с вами.",
    lede2="Это руководство ведёт от загрузки до первого запуска. Знать Linux не нужно, "
          "и никаких команд вводить не придётся.",
    warn_t="Диск компьютера будет полностью очищен.",
    warn_b="Всё на нём будет стёрто без возможности восстановления. Используйте компьютер, "
           "который не жалко, — никогда не свой повседневный.",
    need_h="Что понадобится",
    need=[
        "Компьютер, который не жалко (Intel или AMD), с загрузкой в режиме UEFI. Он станет вашей машиной Home Assistant.",
        "USB-флешка на 2 ГБ или больше.",
        "Интернет — если только файла ещё нет на флешке.",
        "Около получаса. Большая часть — ожидание.",
    ],
    steps_h="Шаг за шагом",
    steps=[
        ("Скачайте файл", "На странице релизов возьмите файл, который заканчивается на .iso "
                          "(около 470 МБ). Версию выбирать не нужно: флешка сама скачает свежую."),
        ("Запишите его на флешку", "Используйте Etcher: выберите файл, выберите флешку, нажмите Flash. "
                                   "Не перетаскивайте файл на флешку, как картинку."),
        ("Измените две настройки", "При включении нажмите F2 или Del. Отключите Secure Boot и "
                                   "поставьте режим SATA в AHCI. Сохраните и выйдите."),
        ("Загрузитесь с флешки", "Оставьте флешку и включите компьютер. Если загрузится старая "
                                 "система, нажмите F12 и выберите USB-флешку."),
        ("Ответьте на вопросы", "Язык (14 вариантов, раскладка подставится сама), откуда взять "
                                "файл, сеть и какой диск можно стереть — введите YES."),
        ("Подождите и выньте флешку", "Он скачает и проверит файл, запишет его и в конце предложит "
                                      "прочитать диск обратно и сравнить. Ответьте да. Выньте "
                                      "флешку, когда он сообщит, что готово."),
    ],
    first_h="Первый запуск",
    first=[
        "Подключите компьютер к роутеру кабелем и включите его.",
        "Откройте http://homeassistant.local — «Preparing Home Assistant» может занять двадцать минут.",
        "Создайте учётную запись и запишите пароль: восстановить его нельзя.",
    ],
    prob_h="Если что-то не работает",
    prob=[
        ("Компьютер загружает старую систему", "Перезагрузитесь, нажмите F12 и выберите флешку. Если её нет в списке, запишите её заново в Etcher."),
        ("Экран остаётся чёрным", "Проверьте в настройках, что Secure Boot отключён, оставьте флешку и попробуйте снова."),
        ("Не находит ни одного диска", "Скорее всего накопитель в режиме RAID, а не AHCI. Измените это и начните заново."),
        ("Адрес не открывается", "Попробуйте http://homeassistant.local:8123 или адрес компьютера из роутера с :8123."),
    ],
    foot="Неофициальный проект, не связанный с Open Home Foundation, Nabu Casa или проектом "
         "Home Assistant. Написан с помощью ИИ, лицензия MIT, без гарантий и поддержки.",
    src="Код и релизы",
    manual="Техническое руководство",
)

STYLE = """  :root {
    --bg: #fbfcfd;
    --card: #ffffff;
    --fg: #1b2733;
    --muted: #5d6b7a;
    --line: #dde5ec;
    --accent: #0a7ea4;
    --accent-soft: #e8f6fb;
    --warn-bg: #fff8e6;
    --warn-line: #e6c675;
    --radius: 12px;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #10161c;
      --card: #172029;
      --fg: #e7eef4;
      --muted: #9db0c0;
      --line: #26323d;
      --accent: #4cc2e6;
      --accent-soft: #122b35;
      --warn-bg: #2a2313;
      --warn-line: #6b5726;
    }
  }
  * { box-sizing: border-box; }
  html { -webkit-text-size-adjust: 100%; }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--fg);
    font: 17.5px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  }
  .wrap { max-width: 44rem; margin: 0 auto; padding: 0 1.25rem; }
  a { color: var(--accent); text-decoration-thickness: 1px; text-underline-offset: 2px; }
  a:hover { text-decoration-thickness: 2px; }

  header.top { border-bottom: 1px solid var(--line); background: var(--card); }
  header.top .wrap {
    display: flex; flex-wrap: wrap; gap: 0.4rem 1.25rem;
    align-items: baseline; justify-content: space-between;
    padding-top: 0.8rem; padding-bottom: 0.8rem;
  }
  header.top .name { font-weight: 650; font-size: 0.95rem; }
  ul.langs {
    list-style: none; display: flex; flex-wrap: wrap; gap: 0.15rem 0.75rem;
    margin: 0; padding: 0; font-size: 0.85rem;
  }
  ul.langs a { text-decoration: none; color: var(--muted); }
  ul.langs a:hover { color: var(--accent); text-decoration: underline; }
  ul.langs [aria-current="page"] { color: var(--fg); font-weight: 650; }

  .hero { padding: 2.5rem 0 0.5rem; }
  h1 { font-size: clamp(1.7rem, 4.5vw, 2.3rem); line-height: 1.18; letter-spacing: -0.02em; margin: 0 0 1rem; }
  .lede { font-size: 1.05rem; margin: 0 0 0.9rem; }

  h2 {
    font-size: 1.25rem; letter-spacing: -0.01em;
    margin: 2.3rem 0 0.9rem; padding-bottom: 0.5rem;
    border-bottom: 1px solid var(--line);
  }
  p { margin: 0 0 1rem; }

  .notice {
    margin: 1.4rem 0 0; padding: 1rem 1.15rem;
    background: var(--warn-bg); border: 1px solid var(--warn-line);
    border-radius: var(--radius);
  }
  .notice strong { display: block; margin-bottom: 0.2rem; }

  ul.need { margin: 0; padding-left: 1.2rem; }
  ul.need li { margin: 0.45rem 0; }

  ol.steps { list-style: none; margin: 0; padding: 0; counter-reset: s; }
  ol.steps > li {
    counter-increment: s; position: relative;
    background: var(--card); border: 1px solid var(--line);
    border-radius: var(--radius);
    padding: 1rem 1.2rem 1rem 3.4rem; margin: 0 0 0.9rem;
  }
  ol.steps > li::before {
    content: counter(s); position: absolute; left: 1rem; top: 0.95rem;
    width: 1.7rem; height: 1.7rem; border-radius: 50%;
    background: var(--accent-soft); color: var(--accent);
    font-size: 0.9rem; font-weight: 700; display: grid; place-items: center;
  }
  ol.steps h3 { font-size: 1rem; margin: 0 0 0.3rem; }
  ol.steps p { margin: 0; font-size: 0.96rem; }

  dl.faq { margin: 0; }
  dl.faq dt { font-weight: 650; margin-top: 1rem; }
  dl.faq dd { margin: 0.2rem 0 0; }

  footer {
    margin-top: 3rem; border-top: 1px solid var(--line);
    padding: 1.4rem 0 2.4rem; color: var(--muted); font-size: 0.86rem;
  }
  footer p { margin: 0.4rem 0; }"""


def language_bar(current):
    items = []
    for code, label, href in LANGS:
        if code == current:
            items.append('<li><span aria-current="page">%s</span></li>' % label)
        else:
            items.append('<li><a href="%s" hreflang="%s">%s</a></li>' % (href, code, label))
    return "    <ul class=\"langs\">\n      " + "\n      ".join(items) + "\n    </ul>"


def page(code, d):
    steps = "\n".join(
        '    <li>\n      <h3>%s</h3>\n      <p>%s</p>\n    </li>' % (h, p)
        for h, p in d["steps"])
    need = "\n".join("    <li>%s</li>" % x for x in d["need"])
    first = "\n".join("    <li>%s</li>" % x for x in d["first"])
    prob = "\n".join("    <dt>%s</dt>\n    <dd>%s</dd>" % (a, b) for a, b in d["prob"])

    return """<!DOCTYPE html>
<html lang="%(code)s">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>%(title)s</title>
<meta name="description" content="%(title)s">
<style>
%(style)s
</style>
</head>
<body>

<header class="top">
  <div class="wrap">
    <span class="name">haos-isoinstall</span>
%(bar)s
  </div>
</header>

<main class="wrap">

  <div class="hero">
    <h1>%(h1)s</h1>
    <p class="lede">%(lede)s</p>
    <p class="lede">%(lede2)s</p>

    <div class="notice">
      <strong>%(warn_t)s</strong>
      %(warn_b)s
    </div>
  </div>

  <h2>%(need_h)s</h2>
  <ul class="need">
%(need)s
  </ul>

  <h2>%(steps_h)s</h2>
  <ol class="steps">
%(steps)s
  </ol>

  <h2>%(first_h)s</h2>
  <ul class="need">
%(first)s
  </ul>

  <h2>%(prob_h)s</h2>
  <dl class="faq">
%(prob)s
  </dl>

</main>

<footer>
  <div class="wrap">
    <p>%(foot)s</p>
    <p>
      <a href="https://github.com/cronner/haos-isoinstall/releases">%(src)s</a> ·
      <a href="https://github.com/cronner/haos-isoinstall/blob/main/README.md">%(manual)s</a> ·
      <a href="https://www.home-assistant.io/">Home Assistant</a>
    </p>
  </div>
</footer>

</body>
</html>
""" % dict(code=code, title=d["title"], h1=d["h1"], lede=d["lede"], lede2=d["lede2"],
           warn_t=d["warn_t"], warn_b=d["warn_b"], need_h=d["need_h"],
           need=need, steps_h=d["steps_h"], steps=steps, first_h=d["first_h"],
           first=first, prob_h=d["prob_h"], prob=prob, foot=d["foot"],
           src=d["src"], manual=d["manual"], style=STYLE, bar=language_bar(code))


out = Path("docs")
for code, _, _ in LANGS:
    if code == "en":
        continue
    assert code in T, "no translation for " + code
    io.open(str(out / (code + ".html")), "w", encoding="utf-8", newline="\n").write(
        page(code, T[code]))
    print("wrote docs/%s.html" % code)
print("%d pages" % (len(T)))
