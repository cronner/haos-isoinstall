#!/bin/bash
# haos-installer.sh — Guided Home Assistant OS installer (bare metal).
#
# Whiptail screens, assisted Wi-Fi, disk selection, verification by read-back.
# Started at boot of a Debian live system. Languages EN/DA/DE/FR (chosen on screen 1).
set -uo pipefail          # no -e: errors are handled to keep the wizard alive
export NEWT_COLORS='root=,blue; window=,lightgray; border=blue,lightgray; title=blue,'

# The kernel writes its messages straight to the console (no 'quiet' at boot, on
# purpose). During the TUI they bleed into the windows -> emergencies only.
quiet_console(){ dmesg -n 1 2>/dev/null || echo 1 > /proc/sys/kernel/printk 2>/dev/null || true; }
loud_console(){  dmesg -n 7 2>/dev/null || echo 7 > /proc/sys/kernel/printk 2>/dev/null || true; }
quiet_console
trap loud_console EXIT

UI_LANG="en"
LOG=/tmp/haos-install.log
: > "$LOG"

# Explicit trace of the decisions. The script's 21 "2>>$LOG" redirections only
# capture stderr on failure: without these lines, the log of a SUCCESSFUL
# installation would be empty, hence useless to archive and attach to a bug
# report. No secret ever goes here (the Wi-Fi PSK does not pass through it).
logx(){ printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG"; }

# ---------------------------------------------------------------------------
# Strings. Variables are injected via printf (%s): no interpolation at
# definition time, otherwise $TARGET & co would be empty at this stage.
# ---------------------------------------------------------------------------
set_strings(){
case "$UI_LANG" in
fr)
  S_TITLE="Installation Home Assistant OS"
  S_WARN="⚠  AVERTISSEMENT — Installation Home Assistant OS"
  S_RESCUE="\n\nTu vas pouvoir sauvegarder le journal, puis éteindre le PC."
  S_HALT_ASK="Que faire maintenant ?\n\nRien ne sera modifié : l'installation est terminée, en échec.\nÉteindre est le choix normal.\n\nLe terminal n'est utile que si tu sais t'en servir."
  S_HALT_OFF="Éteindre le PC"
  S_HALT_SHELL="Ouvrir un terminal"
  S_CANCELLED="Installation annulée."
  S_VFY_ABORT="Le disque ne correspond pas à l'image : ne démarrez pas dessus."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="À VÉRIFIER (mode Legacy/CSM détecté)"
  S_SB_OFF="OK (désactivé)"
  S_SB_ON="À VÉRIFIER (activé — HAOS ne démarrera pas)"
  S_SB_UNK="À VÉRIFIER (état indéterminé)"
  S_WELCOME="Bienvenue.\n\nCet outil installe la dernière version de Home Assistant OS\nsur ce PC, sans ligne de commande.\n\nÉTAT DES PRÉREQUIS :\n  Démarrage   : %s\n  Secure Boot : %s\n\nUn « À VÉRIFIER » signifie que Home Assistant risque de ne\npas démarrer après l'installation. Cela se corrige dans le\nBIOS (touche Suppr/F2 au démarrage). Rien n'est bloqué :\ntu peux continuer quand même.\n\nÀ l'étape du disque, TOUT le disque choisi sera effacé."
  S_NET_ETH="Recherche d'une connexion filaire (Ethernet)..."
  S_NET_NOWIFI="Aucune carte Wi-Fi utilisable détectée.\n\n%s\n\nBranche un câble Ethernet, ou choisis la configuration\nmanuelle à l'écran suivant."
  S_NET_SCAN="Recherche des réseaux Wi-Fi..."
  S_NET_PICK="Sélectionne ton réseau Wi-Fi :"
  S_NET_RESCAN="[ Relancer le scan ]"
  S_NET_RESCAN_D="aucun réseau trouvé ? réessayer"
  S_NET_MANUAL="[ Configuration manuelle ]"
  S_NET_MANUAL_D="SSID caché, WPA entreprise, IP fixe (nmtui)"
  S_NET_ETHRETRY="[ Réessayer l'Ethernet ]"
  S_NET_ETHRETRY_D="câble branché entre-temps"
  S_NET_QUIT="Quitter l'installateur ?\n\nAucun réseau n'est configuré : l'installation ne peut pas\ncontinuer sans accès à Internet."
  S_NET_PSK="Mot de passe du réseau « %s » :\n(affiché en clair pour éviter les fautes de frappe)"
  S_NET_CONN="Connexion à « %s »..."
  S_NET_FAIL="Échec de connexion à « %s ».\n\n%s\n\nVérifie le mot de passe, ou utilise la configuration manuelle."
  S_VER_FETCH="Recherche de la dernière version de Home Assistant OS..."
  S_VER_FAIL="Impossible de déterminer la version de Home Assistant OS.\n\nLes deux sources ont été tentées sans succès :\n  version.home-assistant.io  (canal stable)\n  api.github.com             (dernière publication)\n\nL'installation ne peut pas continuer : sans version, il n'y\na pas d'image à télécharger.\n\nVérifie l'accès à Internet et la résolution DNS, puis\nrelance l'installateur."
  S_VER_NOIMG="Image introuvable pour la version %s :\n%s"
  S_DISK_NONE="Aucun disque interne détecté."
  S_DISK_PICK="Sur quel disque installer Home Assistant OS ?\nTOUT son contenu sera définitivement effacé.\n\nLes disques marqués [!! USB / EXTERNE !!] sont amovibles :\nc'est probablement un disque de sauvegarde, pas la cible."
  S_DISK_SMALL="Le disque %s fait %s Go.\n\nHome Assistant demande 32 Go minimum. L'écriture risque\nd'échouer, ou de laisser trop peu de place à l'usage.\n\nRien n'a encore été effacé."
  S_DISK_CONFIRM="Le disque %s va être ENTIÈREMENT EFFACÉ.\n\nContenu actuel détecté :\n%s\n\nConfirmer l'effacement et l'installation ?"
  S_CONFIRM_T="⚠  DERNIÈRE CONFIRMATION"
  S_STOP="Arrêter (recommandé)"
  S_GOON="Continuer quand même"
  S_STOPPED="Arrêté avant toute modification."
  S_PREP="Préparation du disque %s..."
  S_WRITING="Téléchargement et écriture de HAOS %s.\nNe pas éteindre le PC."
  S_FAIL="Échec de l'installation (code %s).\n\nCause la plus fréquente : une coupure de la connexion Internet\npendant le téléchargement. Le disque a déjà été effacé ;\nrelancer l'installation depuis le début est sans danger.\n\nDétail :\n%s\n\nJournal complet : %s"
  S_VFY_ASK="Vérifier que le disque a été écrit correctement ?\n\nRelecture de %s depuis %s.\nDurée : 1 à 3 minutes selon le disque.\n\nRecommandé, surtout sur un disque ancien."
  S_VFY_RUN="Relecture et vérification du disque..."
  S_VFY_OK="Vérification réussie.\n\nLe contenu du disque correspond exactement à l'image.\n\nSHA256 : %s..."
  S_VFY_KO="ÉCHEC DE LA VÉRIFICATION\n\nLe disque ne correspond pas à l'image écrite :\n  attendu : %s...\n  lu      : %s...\n\nCauses possibles : disque défaillant, câble SATA, mémoire.\nNE PAS utiliser cette installation : recommence, et si\nl'erreur persiste, change de disque."
  S_VFY_SKIP="Empreinte de l'image non calculée : vérification impossible.\nL'installation est probablement correcte (le téléchargement\nest validé par le format compressé)."
  S_LOG_ASK="Copier le journal d'installation sur une clé USB ?\n\nIl sera perdu au redémarrage sinon. C'est le fichier à\njoindre pour signaler le problème."
  S_LOG_OK="Journal copié sur %s\n(fichier haos-install-*.log)\n\nTu peux retirer la clé."
  S_LOG_MENU="Où sauvegarder le journal d'installation ?\n\nAucun support inscriptible n'a été trouvé automatiquement.\nChoisis une solution :"
  S_LOG_M_USB="Brancher une clé USB"
  S_LOG_M_USB_D="attends 5 s, puis valide"
  S_LOG_M_FMT="Reformater cette clé"
  S_LOG_M_FMT_D="efface l'installateur"
  S_LOG_M_SHOW="Afficher à l'écran"
  S_LOG_M_SHOW_D="pour le photographier"
  S_LOG_M_NONE="Ne pas sauvegarder"
  S_LOG_M_NONE_D="le journal sera perdu"
  S_LOG_VTOY="La clé est reconnue, mais réservée par le système de\ndémarrage, et la libérer automatiquement a échoué.\n\nC'est le cas avec Ventoy : l'image d'installation est un\nfichier de cette clé.\n\n➜ DÉBRANCHE puis REBRANCHE la clé, attends 5 secondes, et\n  choisis « Brancher une clé USB » ci-dessous.\n\nL'installateur tourne en mémoire : la débrancher est sans\nconséquence."
  S_LOG_RO="Un support a été trouvé, mais il est en lecture seule.\n\nC'est le cas avec Ventoy : le système d'installation utilise\ncette partition, elle n'est donc pas modifiable.\n\nDébrancher puis rebrancher la clé la libère, ou choisis une\nautre solution."
  S_LOG_DETECT="Détection du support..."
  S_LOG_RETRY="Toujours rien d'inscriptible.\n\nLa clé n'est peut-être pas partitionnée, ou son format\nn'est pas reconnu. Tu peux réessayer avec une autre clé."
  S_LOG_FULL="Un support a bien été trouvé, mais il est plein.\n\nLa place manque pour y écrire le journal. Branche une\nautre clé USB, ou affiche le journal à l'écran à l'étape\nsuivante pour le photographier."
  S_LOG_NONE="Journal non copié.\n\nIl reste consultable dans le terminal :\n  cat %s"
  S_WIFI_PUSH="Réseau Wi-Fi « %s » pré-configuré.\n\nHome Assistant tentera de s'y connecter au premier\ndémarrage — MAIS seulement si ta carte Wi-Fi fait partie\nde celles qu'il prend en charge (sa liste est plus\nrestreinte que celle de cet installateur).\n\nSi Home Assistant n'apparaît pas en ligne après 5 min :\n • branche un câble Ethernet (recommandé), ou\n • signale ta carte au projet Home Assistant OS.\n\nGarde ce PC à portée du Wi-Fi."
  S_WIFI_PUSH_FAIL="Le Wi-Fi n'a pas pu être pré-configuré dans l'image.\n\nHome Assistant démarrera sans réseau : il faudra le\nconnecter ensuite (câble Ethernet, ou clavier+écran sur\nla console HAOS)."
  S_WIFI_PUSH_SKIP="Ce réseau Wi-Fi ne peut pas être pré-configuré.\n\nIl s'appuie sur des certificats ou un mode que Home\nAssistant ne pourra pas reprendre tel quel. Rien n'a été\nécrit : mieux vaut cela qu'un réseau qui ne monte jamais.\n\nÀ FAIRE APRÈS L'INSTALLATION :\n • branche un câble Ethernet (le plus simple), ou\n • configure le Wi-Fi depuis la console de Home Assistant\n   (clavier + écran sur le PC).\n\nLe détail figure dans le journal d'installation."
  S_DONE_LOG="\n\nLa clé a été reformatée : elle redevient une clé USB normale,\net le journal d'installation y a été copié."
  S_FMT_ASK="Reformater la clé USB d'installation ?\n\n%s\n\nElle redeviendrait une clé ordinaire (FAT32), utilisable\npartout, et le journal d'installation y serait copié.\n\n⚠  L'INSTALLATEUR SERA EFFACÉ : pour réinstaller, il faudra\nregraver la clé depuis un autre ordinateur.\n\nL'installation de Home Assistant déjà écrite sur le disque\nn'est pas concernée."
  S_FMT_YES="Reformater la clé"
  S_FMT_NO="Garder l'installateur"
  S_FMT_FAIL="La clé n'a pas pu être reformatée.\n\nRien n'a été touché : elle reste utilisable comme\ninstallateur. Le détail figure dans le journal."
  S_FMT_BROKEN="Le reformatage de la clé a échoué en cours de route.\n\n⚠  La clé n'est plus amorçable : il faudra la regraver pour\ns'en resservir comme installateur.\n\nL'installation de Home Assistant sur le disque n'est pas\nconcernée, elle est terminée."
  S_DONE="Installation terminée.\n\nHome Assistant OS est installé sur %s.\n\n➜ RETIRE LA CLÉ USB MAINTENANT, avant de valider.\n  (l'installateur tourne en mémoire : la clé ne sert plus)\n\nÀ SUIVRE :\n 1. Valide ci-dessous : le PC redémarre sur Home Assistant.\n 2. Garde le câble réseau branché.\n 3. Patiente 2 à 5 minutes (premier démarrage).\n 4. Depuis un autre appareil :  http://homeassistant.local"
;;
de)
  S_TITLE="Installation von Home Assistant OS"
  S_WARN="⚠  WARNUNG — Installation von Home Assistant OS"
  S_RESCUE="\n\nDu kannst jetzt das Protokoll speichern und den PC danach ausschalten."
  S_HALT_ASK="Was jetzt?\n\nEs wird nichts mehr geändert: die Installation ist fehlgeschlagen.\nAusschalten ist die normale Wahl.\n\nDas Terminal ist nur etwas für dich, wenn du dich damit\nauskennst."
  S_HALT_OFF="PC ausschalten"
  S_HALT_SHELL="Terminal öffnen"
  S_CANCELLED="Installation abgebrochen."
  S_VFY_ABORT="Die Platte entspricht nicht dem Image: nicht davon starten."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="PRÜFEN (Legacy/CSM-Modus erkannt)"
  S_SB_OFF="OK (deaktiviert)"
  S_SB_ON="PRÜFEN (aktiviert — HAOS startet nicht)"
  S_SB_UNK="PRÜFEN (Status unklar)"
  S_WELCOME="Willkommen.\n\nDieses Werkzeug installiert die neueste Version von\nHome Assistant OS auf diesem PC, ohne Kommandozeile.\n\nVORAUSSETZUNGEN:\n  Startmodus  : %s\n  Secure Boot : %s\n\n„PRÜFEN“ heißt, dass Home Assistant nach der\nInstallation möglicherweise nicht startet. Das behebst\ndu im BIOS (Entf/F2 beim Einschalten). Nichts ist\ngesperrt: du kannst trotzdem weitermachen.\n\nBeim Schritt „Datenträger“ wird die gewählte Platte\nKOMPLETT gelöscht."
  S_NET_ETH="Suche nach einer Kabelverbindung (Ethernet)..."
  S_NET_NOWIFI="Keine nutzbare WLAN-Karte gefunden.\n\n%s\n\nStecke ein Ethernet-Kabel an, oder nutze im nächsten\nSchritt die manuelle Konfiguration."
  S_NET_SCAN="Suche nach WLAN-Netzen..."
  S_NET_PICK="Wähle dein WLAN-Netz:"
  S_NET_RESCAN="[ Erneut suchen ]"
  S_NET_RESCAN_D="kein Netz gefunden? nochmal versuchen"
  S_NET_MANUAL="[ Manuelle Konfiguration ]"
  S_NET_MANUAL_D="versteckte SSID, WPA-Enterprise, feste IP (nmtui)"
  S_NET_ETHRETRY="[ Ethernet erneut versuchen ]"
  S_NET_ETHRETRY_D="Kabel inzwischen angesteckt"
  S_NET_QUIT="Installation abbrechen?\n\nEs ist kein Netz konfiguriert: ohne Internetzugang kann\ndie Installation nicht weiterlaufen."
  S_NET_PSK="Passwort für das Netz „%s“:\n(wird im Klartext angezeigt, damit du dich nicht vertippst)"
  S_NET_CONN="Verbindung mit „%s“..."
  S_NET_FAIL="Verbindung mit „%s“ fehlgeschlagen.\n\n%s\n\nPrüfe das Passwort, oder nutze die manuelle\nKonfiguration."
  S_VER_FETCH="Suche die neueste Version von Home Assistant OS..."
  S_VER_FAIL="Die Version von Home Assistant OS lässt sich nicht ermitteln.\n\nBeide Quellen wurden ohne Erfolg versucht:\n  version.home-assistant.io  (Stable-Kanal)\n  api.github.com             (letztes Release)\n\nDie Installation kann nicht weiterlaufen: ohne Version\ngibt es kein Image zum Herunterladen.\n\nPrüfe den Internetzugang und die DNS-Auflösung, und\nstarte den Installer neu."
  S_VER_NOIMG="Kein Image für Version %s gefunden:\n%s"
  S_DISK_NONE="Keine interne Festplatte gefunden."
  S_DISK_PICK="Auf welche Platte soll Home Assistant OS installiert werden?\nIHR GESAMTER Inhalt wird endgültig gelöscht.\n\nPlatten mit [!! USB / EXTERN !!] sind wechselbar: das ist\nwahrscheinlich eine Sicherungsplatte, nicht das Ziel."
  S_DISK_SMALL="Die Platte %s hat %s GB.\n\nHome Assistant braucht mindestens 32 GB. Das Schreiben\nkann fehlschlagen oder zu wenig Platz übrig lassen.\n\nBisher wurde nichts gelöscht."
  S_DISK_CONFIRM="Die Platte %s wird KOMPLETT GELÖSCHT.\n\nErkannter aktueller Inhalt:\n%s\n\nLöschen und Installation bestätigen?"
  S_CONFIRM_T="⚠  LETZTE BESTÄTIGUNG"
  S_STOP="Abbrechen (empfohlen)"
  S_GOON="Trotzdem weitermachen"
  S_STOPPED="Vor jeder Änderung abgebrochen."
  S_PREP="Platte %s wird vorbereitet..."
  S_WRITING="HAOS %s wird heruntergeladen und geschrieben.\nSchalte den PC nicht aus."
  S_FAIL="Installation fehlgeschlagen (Code %s).\n\nHäufigste Ursache: die Internetverbindung ist beim\nHerunterladen abgebrochen. Die Platte ist bereits\ngelöscht; die Installation von vorne zu starten ist\nunbedenklich.\n\nDetails:\n%s\n\nVollständiges Protokoll: %s"
  S_VFY_ASK="Prüfen, ob die Platte korrekt geschrieben wurde?\n\n%s werden von %s zurückgelesen.\nDauer: 1 bis 3 Minuten je nach Platte.\n\nEmpfohlen, besonders bei einer älteren Platte."
  S_VFY_RUN="Platte wird zurückgelesen und geprüft..."
  S_VFY_OK="Prüfung erfolgreich.\n\nDer Inhalt der Platte entspricht genau dem Image.\n\nSHA256: %s..."
  S_VFY_KO="PRÜFUNG FEHLGESCHLAGEN\n\nDie Platte entspricht nicht dem geschriebenen Image:\n  erwartet: %s...\n  gelesen : %s...\n\nMögliche Ursachen: defekte Platte, SATA-Kabel,\nSpeicher. DIESE Installation NICHT verwenden: beginne\nneu, und wenn der Fehler bleibt, tausche die Platte."
  S_VFY_SKIP="Der Prüfwert des Images wurde nicht berechnet: Prüfung\nunmöglich. Die Installation ist wahrscheinlich in Ordnung\n(der Download wird durch das komprimierte Format\nvalidiert)."
  S_LOG_ASK="Installationsprotokoll auf einen USB-Stick kopieren?\n\nSonst geht es beim Neustart verloren. Diese Datei gehört\nzu einer Fehlermeldung dazu."
  S_LOG_OK="Protokoll kopiert auf %s\n(Datei haos-install-*.log)\n\nDu kannst den Stick abziehen."
  S_LOG_MENU="Wo soll das Installationsprotokoll gespeichert werden?\n\nEs wurde kein beschreibbarer Datenträger gefunden.\nWähle eine Möglichkeit:"
  S_LOG_M_USB="USB-Stick anstecken"
  S_LOG_M_USB_D="5 s warten, dann bestätigen"
  S_LOG_M_FMT="Diesen Stick neu formatieren"
  S_LOG_M_FMT_D="löscht den Installer"
  S_LOG_M_SHOW="Auf dem Bildschirm anzeigen"
  S_LOG_M_SHOW_D="zum Abfotografieren"
  S_LOG_M_NONE="Nicht speichern"
  S_LOG_M_NONE_D="das Protokoll geht verloren"
  S_LOG_VTOY="Der Stick wird erkannt, ist aber vom Startsystem belegt,\nund das automatische Freigeben ist fehlgeschlagen.\n\nDas passiert mit Ventoy: das Installationsimage ist eine\nDatei auf diesem Stick.\n\n➜ STECKE den Stick AB und wieder AN, warte 5 Sekunden\n  und wähle unten „USB-Stick anstecken“.\n\nDer Installer läuft im Speicher: Abziehen ist\nunbedenklich."
  S_LOG_RO="Ein Datenträger wurde gefunden, ist aber schreibgeschützt.\n\nDas passiert mit Ventoy: das Installationssystem nutzt\ndiese Partition, sie ist deshalb nicht änderbar.\n\nAb- und wieder Anstecken gibt sie frei, oder wähle eine\nandere Möglichkeit."
  S_LOG_DETECT="Datenträger wird gesucht..."
  S_LOG_RETRY="Weiterhin nichts Beschreibbares.\n\nDer Stick ist vielleicht nicht partitioniert, oder sein\nFormat wird nicht erkannt. Du kannst einen anderen\nnehmen."
  S_LOG_FULL="Ein Datenträger wurde gefunden, ist aber voll.\n\nEs ist kein Platz für das Protokoll. Stecke einen anderen\nUSB-Stick an, oder zeige das Protokoll im nächsten Schritt\nauf dem Bildschirm an, um es abzufotografieren."
  S_LOG_NONE="Protokoll nicht kopiert.\n\nEs bleibt im Terminal lesbar:\n  cat %s"
  S_WIFI_PUSH="WLAN-Netz „%s“ vorkonfiguriert.\n\nHome Assistant versucht beim ersten Start, sich damit zu\nverbinden — ABER nur, wenn deine WLAN-Karte zu denen\ngehört, die es unterstützt (seine Liste ist kürzer als die\ndieses Installers).\n\nWenn Home Assistant nach 5 min nicht online ist:\n • Ethernet-Kabel anstecken (empfohlen), oder\n • deine Karte beim Home-Assistant-OS-Projekt melden.\n\nHalte diesen PC in WLAN-Reichweite."
  S_WIFI_PUSH_FAIL="Das WLAN konnte nicht ins Image vorkonfiguriert werden.\n\nHome Assistant startet ohne Netz: du musst es danach\nverbinden (Ethernet-Kabel, oder Tastatur+Bildschirm an der\nHAOS-Konsole)."
  S_WIFI_PUSH_SKIP="Dieses WLAN-Netz lässt sich nicht vorkonfigurieren.\n\nEs beruht auf Zertifikaten oder einem Modus, den Home\nAssistant nicht unverändert übernehmen kann. Es wurde\nnichts geschrieben: besser so als ein Netz, das nie\nhochkommt.\n\nNACH DER INSTALLATION ZU TUN:\n • Ethernet-Kabel anstecken (am einfachsten), oder\n • WLAN in der Konsole von Home Assistant einrichten\n   (Tastatur + Bildschirm am PC).\n\nDetails stehen im Installationsprotokoll."
  S_DONE_LOG="\n\nDer Stick wurde neu formatiert: er ist wieder ein normaler\nUSB-Stick, und das Installationsprotokoll wurde darauf\nkopiert."
  S_FMT_ASK="Den Installations-USB-Stick neu formatieren?\n\n%s\n\nEr würde wieder ein gewöhnlicher FAT32-Stick, überall\nnutzbar, und das Installationsprotokoll würde darauf\nkopiert.\n\n⚠  DER INSTALLER WIRD GELÖSCHT: zum Neuinstallieren\nmüsstest du den Stick an einem anderen Rechner neu\nschreiben.\n\nDie bereits auf die Platte geschriebene Home-Assistant-\nInstallation ist nicht betroffen."
  S_FMT_YES="Stick neu formatieren"
  S_FMT_NO="Installer behalten"
  S_FMT_FAIL="Der Stick konnte nicht neu formatiert werden.\n\nNichts wurde verändert: er bleibt als Installer nutzbar.\nDetails stehen im Protokoll."
  S_FMT_BROKEN="Das Neuformatieren des Sticks ist unterwegs fehlgeschlagen.\n\n⚠  Der Stick ist nicht mehr bootfähig: du müsstest ihn neu\nschreiben, um ihn wieder als Installer zu nutzen.\n\nDie Installation von Home Assistant auf der Platte ist\nnicht betroffen, sie ist fertig."
  S_DONE="Installation abgeschlossen.\n\nHome Assistant OS ist auf %s installiert.\n\n➜ ZIEHE JETZT DEN USB-STICK AB, bevor du bestätigst.\n  (der Installer läuft im Speicher: der Stick wird nicht mehr gebraucht)\n\nWEITER:\n 1. Bestätige unten: der PC startet in Home Assistant.\n 2. Lass das Netzwerkkabel angesteckt.\n 3. Warte 2 bis 5 Minuten (erster Start).\n 4. Von einem anderen Gerät:  http://homeassistant.local"
;;
da)
  S_TITLE="Installation af Home Assistant OS"
  S_WARN="⚠  ADVARSEL — Installation af Home Assistant OS"
  S_RESCUE="\n\nDu kan gemme loggen og derefter slukke PC'en."
  S_HALT_ASK="Hvad nu?\n\nDer ændres ikke mere: installationen mislykkedes.\nAt slukke er det normale valg.\n\nTerminalen er kun noget for dig, hvis du kender den."
  S_HALT_OFF="Sluk PC'en"
  S_HALT_SHELL="Åbn en terminal"
  S_CANCELLED="Installation afbrudt."
  S_VFY_ABORT="Disken svarer ikke til imaget: start ikke fra den."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="TJEK DETTE (Legacy/CSM-tilstand fundet)"
  S_SB_OFF="OK (deaktiveret)"
  S_SB_ON="TJEK DETTE (aktiveret — HAOS starter ikke)"
  S_SB_UNK="TJEK DETTE (tilstand ukendt)"
  S_WELCOME="Velkommen.\n\nDette værktøj installerer den nyeste Home Assistant OS\npå denne PC, uden kommandolinje.\n\nKRAV:\n  Starttilstand : %s\n  Secure Boot   : %s\n\n»TJEK DETTE« betyder, at Home Assistant muligvis ikke\nstarter efter installationen. Det rettes i BIOS\n(Del/F2 ved opstart). Intet er blokeret: du kan fortsætte.\n\nVed disken bliver HELE den valgte disk slettet."
  S_NET_ETH="Søger efter en kabelforbindelse (Ethernet)..."
  S_NET_NOWIFI="Ingen brugbart Wi-Fi-kort fundet.\n\n%s\n\nSæt et Ethernet-kabel i, eller brug den manuelle\nkonfiguration på næste skærm."
  S_NET_SCAN="Søger efter Wi-Fi-netværk..."
  S_NET_PICK="Vælg dit Wi-Fi-netværk:"
  S_NET_RESCAN="[ Søg igen ]"
  S_NET_RESCAN_D="intet netværk? prøv igen"
  S_NET_MANUAL="[ Manuel konfiguration ]"
  S_NET_MANUAL_D="skjult SSID, WPA enterprise, fast IP (nmtui)"
  S_NET_ETHRETRY="[ Prøv Ethernet igen ]"
  S_NET_ETHRETRY_D="kabel sat i i mellemtiden"
  S_NET_QUIT="Forlad installationsprogrammet?\n\nDer er ikke konfigureret et netværk: installationen kan\nikke fortsætte uden internetadgang."
  S_NET_PSK="Adgangskode til netværket »%s«:\n(vises i klartekst for at undgå tastefejl)"
  S_NET_CONN="Forbinder til »%s«..."
  S_NET_FAIL="Kunne ikke forbinde til »%s«.\n\n%s\n\nTjek adgangskoden, eller brug den manuelle\nkonfiguration."
  S_VER_FETCH="Finder den nyeste version af Home Assistant OS..."
  S_VER_FAIL="Kan ikke fastslå versionen af Home Assistant OS.\n\nBegge kilder blev forsøgt uden held:\n  version.home-assistant.io  (stabil kanal)\n  api.github.com             (seneste udgivelse)\n\nInstallationen kan ikke fortsætte: uden version er der\nintet image at hente.\n\nTjek internetadgang og DNS-opslag, og start\ninstallationsprogrammet igen."
  S_VER_NOIMG="Intet image fundet til version %s:\n%s"
  S_DISK_NONE="Ingen intern disk fundet."
  S_DISK_PICK="Hvilken disk skal Home Assistant OS installeres på?\nHELE indholdet bliver slettet permanent.\n\nDiske markeret [!! USB / EKSTERN !!] er flytbare: det er\nsandsynligvis en backupdisk, ikke målet."
  S_DISK_SMALL="Disken %s er %s GB.\n\nHome Assistant kræver mindst 32 GB. Skrivningen kan\nmislykkes eller efterlade for lidt plads.\n\nIntet er slettet endnu."
  S_DISK_CONFIRM="Disken %s bliver HELT SLETTET.\n\nNuværende indhold fundet:\n%s\n\nBekræft sletning og installation?"
  S_CONFIRM_T="⚠  SIDSTE BEKRÆFTELSE"
  S_STOP="Stop (anbefales)"
  S_GOON="Fortsæt alligevel"
  S_STOPPED="Stoppet før nogen ændring."
  S_PREP="Forbereder disken %s..."
  S_WRITING="Henter og skriver HAOS %s.\nSluk ikke PC'en."
  S_FAIL="Installationen mislykkedes (kode %s).\n\nHyppigste årsag: internetforbindelsen faldt ud under\nhentningen. Disken er allerede slettet; at starte\ninstallationen forfra er sikkert.\n\nDetaljer:\n%s\n\nFuld log: %s"
  S_VFY_ASK="Kontroller, at disken blev skrevet korrekt?\n\nLæser %s tilbage fra %s.\nTager 1 til 3 minutter afhængigt af disken.\n\nAnbefales, især på en ældre disk."
  S_VFY_RUN="Læser disken tilbage og kontrollerer..."
  S_VFY_OK="Kontrollen lykkedes.\n\nDiskens indhold svarer præcis til imaget.\n\nSHA256: %s..."
  S_VFY_KO="KONTROLLEN MISLYKKEDES\n\nDisken svarer ikke til det skrevne image:\n  forventet: %s...\n  læst     : %s...\n\nMulige årsager: defekt disk, SATA-kabel, hukommelse.\nBRUG IKKE denne installation: prøv igen, og hvis fejlen\nbliver ved, så skift disk."
  S_VFY_SKIP="Imagets kontrolsum blev ikke beregnet: kontrol umulig.\nInstallationen er sandsynligvis i orden (hentningen\nvalideres af det komprimerede format)."
  S_LOG_ASK="Kopier installationsloggen til et USB-stik?\n\nEllers går den tabt ved genstart. Det er filen, du\nvedhæfter, når du rapporterer problemet."
  S_LOG_OK="Log kopieret til %s\n(fil haos-install-*.log)\n\nDu kan tage stikket ud."
  S_LOG_MENU="Hvor skal installationsloggen gemmes?\n\nDer blev ikke fundet et skrivbart medie automatisk.\nVælg en mulighed:"
  S_LOG_M_USB="Sæt et USB-stik i"
  S_LOG_M_USB_D="vent 5 s, og bekræft"
  S_LOG_M_FMT="Formatér dette stik"
  S_LOG_M_FMT_D="sletter installationsprogrammet"
  S_LOG_M_SHOW="Vis på skærmen"
  S_LOG_M_SHOW_D="for at fotografere det"
  S_LOG_M_NONE="Gem ikke"
  S_LOG_M_NONE_D="loggen går tabt"
  S_LOG_VTOY="Stikket genkendes, men er reserveret af start-systemet,\nog frigivelsen mislykkedes.\n\nDet sker med Ventoy: installationsimaget er en fil på\ndette stik.\n\n➜ TAG STIKKET UD og sæt det I IGEN, vent 5 sekunder,\n  og vælg »Sæt et USB-stik i« nedenfor.\n\nInstallationsprogrammet kører i hukommelsen: det er\nuskadeligt at tage det ud."
  S_LOG_RO="Et medie blev fundet, men det er skrivebeskyttet.\n\nDet sker med Ventoy: installationssystemet bruger den\npartition, så den kan ikke ændres.\n\nAt tage stikket ud og sætte det i igen frigiver det, eller\nvælg en anden mulighed."
  S_LOG_DETECT="Søger efter medie..."
  S_LOG_RETRY="Stadig intet skrivbart.\n\nStikket er måske ikke partitioneret, eller formatet kendes\nikke. Du kan prøve et andet."
  S_LOG_FULL="Et medie blev fundet, men det er fuldt.\n\nDer er ikke plads til loggen. Sæt et andet USB-stik i,\neller vis loggen på skærmen i næste trin for at\nfotografere den."
  S_LOG_NONE="Log ikke kopieret.\n\nDen kan stadig læses i terminalen:\n  cat %s"
  S_WIFI_PUSH="Wi-Fi-netværket »%s« er forkonfigureret.\n\nHome Assistant forsøger at forbinde ved første opstart —\nMEN kun hvis dit Wi-Fi-kort er blandt dem, den\nunderstøtter (listen er kortere end dette\ninstallationsprograms).\n\nHvis Home Assistant ikke er online efter 5 min:\n • sæt et Ethernet-kabel i (anbefales), eller\n • rapportér dit kort til Home Assistant OS-projektet.\n\nHold denne PC inden for Wi-Fi-rækkevidde."
  S_WIFI_PUSH_FAIL="Wi-Fi kunne ikke forkonfigureres i imaget.\n\nHome Assistant starter uden netværk: du må forbinde det\nbagefter (Ethernet-kabel, eller tastatur+skærm på\nHAOS-konsollen)."
  S_WIFI_PUSH_SKIP="Dette Wi-Fi-netværk kan ikke forkonfigureres.\n\nDet bygger på certifikater eller en tilstand, som Home\nAssistant ikke kan overtage som den er. Intet blev skrevet:\ndet er bedre end et netværk, der aldrig kommer op.\n\nGØR DETTE EFTER INSTALLATIONEN:\n • sæt et Ethernet-kabel i (nemmest), eller\n • konfigurér Wi-Fi fra Home Assistant-konsollen\n   (tastatur + skærm på PC'en).\n\nDetaljerne står i installationsloggen."
  S_DONE_LOG="\n\nStikket blev formateret: det er et normalt USB-stik igen,\nog installationsloggen blev kopieret over på det."
  S_FMT_ASK="Formatér installations-USB-stikket?\n\n%s\n\nDet bliver et almindeligt FAT32-stik, brugbart overalt,\nog installationsloggen kopieres over på det.\n\n⚠  INSTALLATIONSPROGRAMMET SLETTES: for at installere igen\nskal du skrive stikket på ny fra en anden computer.\n\nDen Home Assistant-installation, der allerede er skrevet\ntil disken, er ikke berørt."
  S_FMT_YES="Formatér stikket"
  S_FMT_NO="Behold installationsprogrammet"
  S_FMT_FAIL="Stikket kunne ikke formateres.\n\nIntet blev rørt: det kan stadig bruges som\ninstallationsprogram. Detaljerne står i loggen."
  S_FMT_BROKEN="Formateringen af stikket mislykkedes undervejs.\n\n⚠  Stikket kan ikke længere starte: du skal skrive det igen\nfor at bruge det som installationsprogram.\n\nHome Assistant-installationen på disken er ikke berørt,\nden er færdig."
  S_DONE="Installationen er færdig.\n\nHome Assistant OS er installeret på %s.\n\n➜ TAG USB-STIKKET UD NU, før du bekræfter.\n  (installationsprogrammet kører i hukommelsen: stikket bruges ikke mere)\n\nNÆSTE:\n 1. Bekræft nedenfor: PC'en genstarter i Home Assistant.\n 2. Lad netværkskablet sidde i.\n 3. Vent 2 til 5 minutter (første opstart).\n 4. Fra en anden enhed:  http://homeassistant.local"
;;
*)
  S_TITLE="Home Assistant OS installation"
  S_WARN="⚠  WARNING — Home Assistant OS installation"
  S_RESCUE="\n\nYou will be able to save the log, then power the PC off."
  S_HALT_ASK="What now?\n\nNothing more will change: the installation ended in failure.\nPowering off is the normal choice.\n\nThe terminal is only useful if you know your way around it."
  S_HALT_OFF="Power off"
  S_HALT_SHELL="Open a terminal"
  S_CANCELLED="Installation cancelled."
  S_VFY_ABORT="The disk does not match the image: do not boot from it."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="CHECK THIS (Legacy/CSM mode detected)"
  S_SB_OFF="OK (disabled)"
  S_SB_ON="CHECK THIS (enabled — HAOS will not boot)"
  S_SB_UNK="CHECK THIS (state unknown)"
  S_WELCOME="Welcome.\n\nThis tool installs the latest Home Assistant OS on this PC,\nwith no command line involved.\n\nREQUIREMENTS CHECK:\n  Boot mode   : %s\n  Secure Boot : %s\n\n\"CHECK THIS\" means Home Assistant may not boot after the\ninstall. Fix it in the BIOS (Del/F2 at power-on). Nothing\nis blocked: you may continue anyway.\n\nAt the disk step, the WHOLE disk you pick will be erased."
  S_NET_ETH="Looking for a wired (Ethernet) connection..."
  S_NET_NOWIFI="No usable Wi-Fi adapter detected.\n\n%s\n\nPlug in an Ethernet cable, or use manual configuration on\nthe next screen."
  S_NET_SCAN="Scanning for Wi-Fi networks..."
  S_NET_PICK="Select your Wi-Fi network:"
  S_NET_RESCAN="[ Scan again ]"
  S_NET_RESCAN_D="no network found? retry"
  S_NET_MANUAL="[ Manual configuration ]"
  S_NET_MANUAL_D="hidden SSID, WPA enterprise, static IP (nmtui)"
  S_NET_ETHRETRY="[ Retry Ethernet ]"
  S_NET_ETHRETRY_D="cable plugged in meanwhile"
  S_NET_QUIT="Quit the installer?\n\nNo network is configured: the installation cannot continue\nwithout Internet access."
  S_NET_PSK="Password for network \"%s\":\n(shown in clear text to avoid typos)"
  S_NET_CONN="Connecting to \"%s\"..."
  S_NET_FAIL="Failed to connect to \"%s\".\n\n%s\n\nCheck the password, or use manual configuration."
  S_VER_FETCH="Looking up the latest Home Assistant OS version..."
  S_VER_FAIL="Could not determine the Home Assistant OS version.\n\nBoth sources were tried without success:\n  version.home-assistant.io  (stable channel)\n  api.github.com             (latest release)\n\nThe installation cannot continue: with no version there is\nno image to download.\n\nCheck Internet access and DNS resolution, then start the\ninstaller again."
  S_VER_NOIMG="No image found for version %s:\n%s"
  S_DISK_NONE="No internal disk detected."
  S_DISK_PICK="Which disk should Home Assistant OS be installed on?\nALL of its contents will be permanently erased.\n\nDisks marked [!! USB / EXTERNAL !!] are removable: that is\nprobably a backup drive, not your target."
  S_DISK_SMALL="Disk %s is %s GB.\n\nHome Assistant needs 32 GB minimum. Writing may fail, or\nleave too little room to be usable.\n\nNothing has been erased yet."
  S_DISK_CONFIRM="Disk %s will be COMPLETELY ERASED.\n\nCurrent contents detected:\n%s\n\nConfirm erase and install?"
  S_CONFIRM_T="⚠  FINAL CONFIRMATION"
  S_STOP="Stop (recommended)"
  S_GOON="Continue anyway"
  S_STOPPED="Stopped before any change."
  S_PREP="Preparing disk %s..."
  S_WRITING="Downloading and writing HAOS %s.\nDo not power off the PC."
  S_FAIL="Installation failed (code %s).\n\nMost common cause: the Internet connection dropped during the\ndownload. The disk has already been erased; starting the\ninstallation over from scratch is safe.\n\nDetails:\n%s\n\nFull log: %s"
  S_VFY_ASK="Verify that the disk was written correctly?\n\nReads back %s from %s.\nTakes 1 to 3 minutes depending on the disk.\n\nRecommended, especially on an older disk."
  S_VFY_RUN="Reading back and verifying the disk..."
  S_VFY_OK="Verification passed.\n\nThe disk contents match the image exactly.\n\nSHA256: %s..."
  S_VFY_KO="VERIFICATION FAILED\n\nThe disk does not match the image written:\n  expected: %s...\n  read    : %s...\n\nLikely causes: failing disk, SATA cable, memory.\nDO NOT use this installation: try again, and if the error\npersists, replace the disk."
  S_VFY_SKIP="Image checksum was not computed: cannot verify.\nThe installation is most likely fine (the download is\nvalidated by the compressed format itself)."
  S_LOG_ASK="Copy the installation log to a USB stick?\n\nIt will be lost on reboot otherwise. This is the file to\nattach when reporting the problem."
  S_LOG_OK="Log copied to %s\n(file haos-install-*.log)\n\nYou can remove the stick."
  S_LOG_MENU="Where should the installation log be saved?\n\nNo writable medium was found automatically.\nPick an option:"
  S_LOG_M_USB="Plug in a USB stick"
  S_LOG_M_USB_D="wait 5 s, then confirm"
  S_LOG_M_FMT="Reformat this stick"
  S_LOG_M_FMT_D="erases the installer"
  S_LOG_M_SHOW="Show on screen"
  S_LOG_M_SHOW_D="to photograph it"
  S_LOG_M_NONE="Do not save"
  S_LOG_M_NONE_D="the log will be lost"
  S_LOG_VTOY="The stick is recognised, but reserved by the boot system,\nand releasing it automatically failed.\n\nThis happens with Ventoy: the installation image is a file on\nthis stick.\n\n➜ UNPLUG then REPLUG the stick, wait 5 seconds, and pick\n  \"Plug in a USB stick\" below.\n\nThe installer runs from memory: unplugging it is harmless."
  S_LOG_RO="A medium was found, but it is read-only.\n\nThis happens with Ventoy: the install system is using that\npartition, so it cannot be modified.\n\nUnplugging and replugging the stick frees it, or pick another\noption."
  S_LOG_DETECT="Detecting media..."
  S_LOG_RETRY="Still nothing writable.\n\nThe stick may be unpartitioned, or its format is not\nrecognised. You can try another one."
  S_LOG_FULL="A medium was found, but it is full.\n\nThere is not enough room to write the log. Plug in another\nUSB stick, or display the log on screen at the next step to\nphotograph it."
  S_LOG_NONE="Log not copied.\n\nIt is still readable from the shell:\n  cat %s"
  S_WIFI_PUSH="Wi-Fi network \"%s\" pre-configured.\n\nHome Assistant will try to connect on first boot — BUT\nonly if your Wi-Fi card is among those it supports (its\nlist is narrower than this installer's).\n\nIf Home Assistant is not online after 5 min:\n • plug in an Ethernet cable (recommended), or\n • report your card to the Home Assistant OS project.\n\nKeep this PC within Wi-Fi range."
  S_WIFI_PUSH_FAIL="Wi-Fi could not be pre-configured into the image.\n\nHome Assistant will boot with no network: you will have to\nconnect it afterwards (Ethernet cable, or keyboard+screen\non the HAOS console)."
  S_WIFI_PUSH_SKIP="This Wi-Fi network cannot be pre-configured.\n\nIt relies on certificates or a mode Home Assistant could not\npick up as-is. Nothing was written: better that than a\nnetwork that never comes up.\n\nTO DO AFTER THE INSTALL:\n • plug in an Ethernet cable (simplest), or\n • configure Wi-Fi from the Home Assistant console\n   (keyboard + screen on the PC).\n\nDetails are in the installation log."
  S_DONE_LOG="\n\nThe stick was reformatted: it is a normal USB stick again,\nand the installation log was copied onto it."
  S_FMT_ASK="Reformat the installer USB stick?\n\n%s\n\nIt would become an ordinary FAT32 stick, usable anywhere,\nand the installation log would be copied onto it.\n\n⚠  THE INSTALLER WILL BE ERASED: to reinstall, you would\nhave to write the stick again from another computer.\n\nThe Home Assistant installation already written to the disk\nis not affected."
  S_FMT_YES="Reformat the stick"
  S_FMT_NO="Keep the installer"
  S_FMT_FAIL="The stick could not be reformatted.\n\nNothing was touched: it is still usable as an installer.\nDetails are in the log."
  S_FMT_BROKEN="Reformatting the stick failed partway through.\n\n⚠  The stick is no longer bootable: you will have to write it\nagain to reuse it as an installer.\n\nThe Home Assistant installation on the disk is not affected,\nit is complete."
  S_DONE="Installation complete.\n\nHome Assistant OS is installed on %s.\n\n➜ REMOVE THE USB STICK NOW, before confirming.\n  (the installer runs from memory: the stick is no longer used)\n\nNEXT:\n 1. Confirm below: the PC reboots into Home Assistant.\n 2. Keep the network cable plugged in.\n 3. Wait 2 to 5 minutes (first boot).\n 4. From another device:  http://homeassistant.local"
;;
esac
}

# ---------------------------------------------------------------------------
# whiptail neither resizes anything nor scrolls: text taller than the box is
# silently cut. So we compute the geometry from the text.
# The strings carry literal \n (whiptail interprets them itself): we measure on
# an expanded copy, but hand the original to whiptail so that any backslash
# coming from the log is not altered.
wt_dims(){                                  # <text> -> WT_H, WT_W, WT_SCROLL
  local body line len inner lines=0 max=0 rows cols
  body=$(printf '%b' "$1")
  rows=$(tput lines 2>/dev/null) || rows=24
  cols=$(tput cols  2>/dev/null) || cols=80
  [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80

  while IFS= read -r line; do
    len=${#line}; (( len > max )) && max=$len
  done <<< "$body"

  WT_W=$(( max + 6 ))
  (( WT_W < 40 ))        && WT_W=40
  (( WT_W > cols - 4 ))  && WT_W=$(( cols - 4 ))

  inner=$(( WT_W - 4 )); (( inner < 1 )) && inner=1
  while IFS= read -r line; do
    len=${#line}
    (( len < 1 )) && len=1                  # an empty line still takes 1 line
    lines=$(( lines + (len + inner - 1) / inner ))
  done <<< "$body"

  WT_SCROLL=""
  WT_H=$(( lines + 7 ))                     # margin of the script's convention
  if (( WT_H > rows - 2 )); then            # too tall for the screen -> scrollbar
    WT_H=$(( rows - 2 )); WT_SCROLL="--scrolltext"
  fi
}

wt_msg(){                                   # <title> <text>
  local t="$1"
  [ -n "${STEP:-}" ] && t="$t  [$STEP]"    # language-neutral progress marker
  wt_dims "$2"
  whiptail --title "$t" $WT_SCROLL --msgbox "$2" "$WT_H" "$WT_W"
}

wt_yesno(){                                 # <title> <text> [whiptail args...]
  local title="$1" text="$2"; shift 2
  [ -n "${STEP:-}" ] && title="$title  [$STEP]"
  wt_dims "$text"
  whiptail --title "$title" $WT_SCROLL "$@" --yesno "$text" "$WT_H" "$WT_W"
}

# whiptail --menu: the width must hold the longest LABEL PLUS the longest
# DESCRIPTION, otherwise the lines overflow the frame. Hard-coded dimensions
# cannot adapt to that -- an unknown disk model or SSID has an unpredictable
# length. Prints the chosen label on stdout.
wt_menu(){                    # <title> <prompt> <list height> <tag> <desc>...
  local title="$1" text="$2" listh="$3"; shift 3
  [ -n "${STEP:-}" ] && title="$title  [$STEP]"
  local i=0 tagw=0 descw=0 a rows cols w h lines
  for a in "$@"; do
    if [ $(( i % 2 )) -eq 0 ]; then (( ${#a} > tagw ))  && tagw=${#a}
    else                            (( ${#a} > descw )) && descw=${#a}
    fi
    i=$(( i + 1 ))
  done
  rows=$(tput lines 2>/dev/null) || rows=24
  cols=$(tput cols  2>/dev/null) || cols=80
  [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
  [[ "$cols" =~ ^[0-9]+$ ]] || cols=80

  wt_dims "$text"                     # WT_W for the prompt, WT_H = lines + 7
  lines=$(( WT_H - 7 ))
  w=$(( tagw + descw + 12 ))          # label + description + whiptail frame
  (( WT_W > w ))     && w=$WT_W
  (( w > cols - 4 )) && w=$(( cols - 4 ))
  (( w < 40 ))       && w=40

  # Height: prompt + list + frame. We trim the LIST if the screen is too short,
  # rather than letting whiptail truncate it.
  h=$(( lines + listh + 8 ))
  if (( h > rows - 2 )); then
    listh=$(( rows - 2 - lines - 8 ))
    (( listh < 3 )) && listh=3
    h=$(( lines + listh + 8 ))
    (( h > rows - 2 )) && h=$(( rows - 2 ))
  fi
  whiptail --title "$title" --menu "$text" "$h" "$w" "$listh" "$@" 3>&1 1>&2 2>&3
}

# End of the run on error. We POWER OFF by default rather than dropping to a
# shell: a bash prompt means nothing to the intended audience. The terminal
# stays reachable through the second button -- and not through Ctrl+Alt+F2,
# whose availability depends on a getty and a password we do not control
# (the service occupies tty1 and the live system switches to multi-user.target).

# IMMEDIATE power-off. The system runs entirely from RAM ('toram'): nothing in
# the current session needs to survive, and a full systemd shutdown -- stopping
# units, unmounting, timeouts -- takes tens of seconds and can hang on a
# reluctant unit. We short-circuit it.
# The 'sync' remains ESSENTIAL: the log may just have been written to a USB
# stick, and the target disk image must be flat on the medium.
halt_now(){
  sync
  clear
  # -ff: immediate shutdown without going through the service manager.
  poweroff -ff 2>/dev/null || poweroff -f 2>/dev/null || poweroff 2>/dev/null || true
  sleep 3
  # Kernel fallback if systemd did not take over: SysRq 'o' cuts the power from
  # the kernel, with no user space.
  # Redirection on the GROUP, not on 'echo': the shell reports an open failure,
  # and its message would escape a 2>/dev/null set on echo.
  { echo 1 > /proc/sys/kernel/sysrq; } 2>/dev/null || true
  { echo o > /proc/sysrq-trigger; }   2>/dev/null || true
}

die(){
  wt_msg "$S_TITLE" "$1$S_RESCUE"
  save_log
  loud_console
  if wt_yesno "$S_TITLE" "$S_HALT_ASK" --yes-button "$S_HALT_OFF" --no-button "$S_HALT_SHELL"; then
    halt_now
  fi
  clear; exec bash
}

# ---------------------------------------------------------------------------
# SCREEN 1: language + keyboard in a single question.
# The layout does NOT imply the language (a French speaker may use a US QWERTY)
# -> every line states both explicitly, nothing is inferred.
# Applies the layout. NB: two naming worlds coexist --
#   - console-setup / setupcon: X11 names (fr, be, ch+fr variant, ca, us, gb, de)
#   - loadkeys: console keymap names (fr-latin9, cf, fr_CH, uk...)
# console-setup is installed and is authoritative via /etc/default/keyboard: it
# is the one to drive, otherwise it re-applies its config over loadkeys.
apply_keymap(){
  local layout="$1" variant="${2:-}" out=""

  if [ -w /etc/default/keyboard ] && command -v setupcon >/dev/null 2>&1; then
    sed -i -e "s/^XKBLAYOUT=.*/XKBLAYOUT=\"$layout\"/" \
           -e "s/^XKBVARIANT=.*/XKBVARIANT=\"$variant\"/" /etc/default/keyboard 2>>"$LOG"
    grep -q '^XKBLAYOUT=' /etc/default/keyboard || echo "XKBLAYOUT=\"$layout\"" >> /etc/default/keyboard
    grep -q '^XKBVARIANT=' /etc/default/keyboard || echo "XKBVARIANT=\"$variant\"" >> /etc/default/keyboard
    out=$(setupcon --force 2>&1) && return 0
  fi

  # loadkeys fallback, with translation to the console keymap names
  local km="$layout"
  case "$layout:$variant" in
    fr:)     km="fr-latin9" ;;
    be:)     km="be-latin1" ;;
    ch:fr)   km="fr_CH-latin1" ;;
    ch:de)   km="de_CH-latin1" ;;
    ca:*)    km="cf" ;;
    gb:)     km="uk" ;;
    de:)     km="de-latin1" ;;
    dk:)     km="dk-latin1" ;;
  esac
  out="$out"$'\n'"$(loadkeys "$km" 2>&1)" && return 0

  # No more silent failure: that is what masked the previous bug.
  wt_msg "$S_TITLE" \
    "Keyboard layout could not be applied / La disposition n'a pas pu être appliquée :\n\n$(echo "$out" | cut -c1-64 | head -6)\n\nQWERTY/AZERTY may be wrong. Use the manual config if needed."
  return 1
}

# ---------------------------------------------------------------------------
# SCREEN 1: language + keyboard in a single question.
# The layout does NOT imply the language (a French speaker may use a US QWERTY)
# -> every line states both explicitly, nothing is inferred.
choose_lang_keyboard(){
  local sel
  sel=$(whiptail --title "Language & keyboard" --menu \
    "Choose language and keyboard layout" \
    21 70 13 \
    "en|us|"    "English   |  QWERTY   (US)" \
    "en|gb|"    "English   |  QWERTY   (UK)" \
    "en|de|"    "English   |  QWERTZ   (DE)" \
    "da|dk|"    "Dansk     |  QWERTY   (DK)" \
    "de|de|"    "Deutsch   |  QWERTZ   (DE)" \
    "de|ch|de"  "Deutsch   |  QWERTZ   (CH)" \
    "fr|fr|"    "French    |  AZERTY   (France)" \
    "fr|be|"    "French    |  AZERTY   (Belgium)" \
    "fr|ch|fr"  "French    |  QWERTZ   (Switzerland)" \
    "fr|ca|"    "French    |  QWERTY   (Canada)" \
    "fr|us|"    "French    |  QWERTY   (US)" \
    3>&1 1>&2 2>&3) || sel="en|us|"

  UI_LANG="${sel%%|*}"
  local rest="${sel#*|}"
  apply_keymap "${rest%%|*}" "${rest#*|}"
  set_strings
}

have_net(){ curl -fsI --max-time 5 https://github.com >/dev/null 2>&1; }

# UUID of the ACTIVE Wi-Fi connection, whatever way it was created (guided
# walkthrough or nmtui). Empty when there is none.
active_wifi_uuid(){
  nmcli -t -f UUID,TYPE connection show --active 2>/dev/null \
    | awk -F: '$2=="802-11-wireless" || $2=="wifi" {print $1; exit}'
}

# Details of the Wi-Fi link: band, 802.11 generation and encryption.
# Why it matters:
#   - band: 6 GHz needs a recent kernel, firmware AND regulatory domain.
#     It works here but not necessarily under HAOS -> a real failure vector.
#   - encryption: it is what the profile dropped on hassos-boot has to
#     reproduce. Any gap (pure WPA3, open network, 802.1X) and HAOS will not
#     connect, while the installer announces success.
#
# WARNING, two traps fixed here after a wrong diagnosis in a real test:
#   1. the current AP is marked with a '*' in IN-USE, NOT with "yes" in
#      ACTIVE -- a filter on ACTIVE never matches and everything comes out empty;
#   2. an indeterminate value must NEVER become an assertion. A
#      "${sec:-NONE (open network)}" made a WPA2 look like an open network. We
#      therefore distinguish three states: detected / confirmed open /
#      indeterminate, and we only warn on a positive detection.
# Authoritative source: the key-mgmt of the active connection, which depends on
# no display marker.
# Neither the SSID nor the BSSID is logged: 'iw link' exposes them, we only
# extract the frequency and the generation token.
log_wifi_link(){
  # km initialised: otherwise 'set -u' makes the script fail when no active
  # Wi-Fi connection is found and the assignment block is skipped.
  local dev="$1" drv="${2:-}" iwout freq band gen km="" sec uuid

  iwout=$(iw dev "$dev" link 2>/dev/null)
  freq=$(printf '%s\n' "$iwout" \
         | sed -n 's/^[[:space:]]*freq:[[:space:]]*\([0-9]\{3,\}\).*/\1/p' | head -1)

  band="indeterminate"
  if [ -n "$freq" ]; then
    if   [ "$freq" -lt 3000 ]; then band="2.4 GHz"
    elif [ "$freq" -lt 5925 ]; then band="5 GHz"
    else                            band="6 GHz"
    fi
  fi

  # Generation deduced from the rate token: EHT=Wi-Fi 7, HE=6, VHT=5, HT/MCS=4.
  case "$iwout" in
    *EHT-MCS*) gen="802.11be (Wi-Fi 7)" ;;
    *HE-MCS*)  gen="802.11ax (Wi-Fi 6)" ;;
    *VHT-MCS*) gen="802.11ac (Wi-Fi 5)" ;;
    *MCS*)     gen="802.11n (Wi-Fi 4)"  ;;
    "")        gen="indeterminate"      ;;   # iw silent: do not invent anything
    *)         gen="legacy a/b/g"       ;;
  esac

  # Effective key-mgmt of the active connection. Three states to distinguish.
  uuid=$(active_wifi_uuid)
  if [ -n "$uuid" ]; then
    km=$(nmcli -g 802-11-wireless-security.key-mgmt connection show "$uuid" 2>/dev/null)
  fi
  # String advertised by the AP, as a complement: '*' in IN-USE is the current AP.
  sec=$(nmcli -t -f IN-USE,SECURITY dev wifi list 2>/dev/null \
        | awk -F: '$1=="*"{print $2; exit}')

  logx "network: Wi-Fi $gen, band ${band}${freq:+ (${freq} MHz)}"
  logx "network: Wi-Fi link -- check that HAOS ships the driver ${drv:-?}"

  if [ -n "$km" ]; then
    logx "network: encryption key-mgmt=$km${sec:+ (AP advertises: $sec)}"
    # Warnings on a POSITIVE detection only.
    case "$km" in
      sae)     logx "network: pure WPA3 (SAE) -- the injected profile must carry key-mgmt=sae" ;;
      wpa-eap|wpa-eap-suite-b-192)
               logx "network: WARNING 802.1X (enterprise) -- profile injectable only without certificates" ;;
      none)    logx "network: WARNING WEP or no encryption -- check the injected profile" ;;
    esac
  elif [ -n "$uuid" ]; then
    logx "network: encryption NONE (open network confirmed)"
    logx "network: WARNING open network -- the injected profile must carry no secret"
  else
    # No active Wi-Fi connection identified: we conclude nothing.
    logx "network: encryption indeterminate (no active Wi-Fi connection seen by nmcli)"
  fi
}

# Logs the link type that was used (Ethernet or Wi-Fi) and the HARDWARE involved.
# This is the most useful piece of information in the log: HAOS covers fewer
# Wi-Fi cards than this installer does, so when HAOS boots with no network after
# a successful installation, the DRIVER name is what you need to decide.
# Called ONCE after setup_network: that one has five exit points (immediate
# Ethernet, Ethernet after waiting, Wi-Fi, nmtui, Ethernet retry), and
# instrumenting them separately would be fragile.
# Neither lspci nor ethtool in the ISO -> nmcli, which already exposes
# vendor/product/driver, with a sysfs fallback (the modalias carries the PCI/USB
# identifiers of the component).
log_active_net(){
  local dev typ vendor product driver modalias found=0
  while IFS= read -r dev; do
    [ -n "$dev" ] || continue
    typ=$(nmcli -g GENERAL.TYPE device show "$dev" 2>/dev/null | head -1)
    case "$typ" in ethernet|wifi) ;; *) continue ;; esac
    found=1
    vendor=$(nmcli -g GENERAL.VENDOR  device show "$dev" 2>/dev/null | head -1)
    product=$(nmcli -g GENERAL.PRODUCT device show "$dev" 2>/dev/null | head -1)
    driver=$(nmcli -g GENERAL.DRIVER  device show "$dev" 2>/dev/null | head -1)
    # sysfs fallbacks, useful if nmcli stays silent (unmanaged card, incomplete udev).
    # We check that the link exists: otherwise readlink -f could return a made-up
    # path and basename would derive a bogus driver name from it.
    if [ -z "$driver" ] && [ -L "/sys/class/net/$dev/device/driver" ]; then
      driver=$(basename "$(readlink -f "/sys/class/net/$dev/device/driver")")
    fi
    modalias=$(cat "/sys/class/net/$dev/device/modalias" 2>/dev/null)
    logx "network: $typ via $dev -- $(echo "${vendor:-?} ${product:-?}" | xargs)"
    logx "network: driver=${driver:-unknown} modalias=${modalias:-unknown}"
    [ "$typ" = "wifi" ] && log_wifi_link "$dev" "$driver"
  done < <(nmcli -t -f DEVICE,STATE device status 2>/dev/null \
           | awk -F: '$2=="connected"{print $1}')
  [ "$found" -eq 1 ] || logx "network: no connected interface identified by nmcli"
}

boot_status(){ [ -d /sys/firmware/efi ] && echo "$S_OK_UEFI" || echo "$S_BAD_UEFI"; }

secureboot_status(){
  # mokutil handles the awkward cases (missing efivarfs, multiple GUIDs).
  # Fallback: raw read of the efivar (4 attribute bytes, then the value).
  local out sb f
  if command -v mokutil >/dev/null 2>&1; then
    out=$(mokutil --sb-state 2>/dev/null)
    case "$out" in
      *disabled*|*désactivé*|*deaktiviert*|*deaktiveret*) echo "$S_SB_OFF"; return ;;
      *enabled*)              echo "$S_SB_ON";  return ;;
    esac
  fi
  for f in /sys/firmware/efi/efivars/SecureBoot-*; do
    [ -e "$f" ] || continue
    sb=$(od -An -t u1 -j4 -N1 "$f" 2>/dev/null | tr -d ' '); break
  done
  case "${sb:-}" in
    0) echo "$S_SB_OFF" ;;
    1) echo "$S_SB_ON" ;;
    *) echo "$S_SB_UNK" ;;
  esac
}

# ---------------------------------------------------------------------------
# Log: /tmp dies with the live system. We do NOT CREATE a partition on the
# installation medium (fragile when mounted, breaks Ventoy, impossible on a CD,
# lost on the next flash). Unnecessary anyway: a written stick already exposes
# its ESP as FAT.
# Copies the log onto a partition. 0 = written, 1 = cannot mount,
# 2 = mounted but too small (or copy refused).
# NB: we query lsblk ONE COLUMN AT A TIME. With several columns, an empty value
#     (TRAN, FSTYPE...) shifts the following fields when read back.
# Is the partition claimed by a device-mapper? That is the case under Ventoy:
# the ISO is a FILE on the exFAT partition, which Ventoy exposes as dm-linear.
# The partition is therefore claimed by dm and refuses a read-write mount --
# hence the "unplug/replug" workaround, which tears that mapping down.
dm_holds(){
  local p="$1" s
  for s in /sys/block/dm-*/slaves/*; do
    [ -e "$s" ] || continue
    [ "$(basename "$s")" = "$p" ] && return 0
  done
  return 1
}

# Releases the partition claimed by the boot mapping (Ventoy), so the log can be
# written there without asking the user to unplug the stick.
#
# ABSOLUTE SAFETY CONDITION: remove nothing if the live system still reads the
# medium. 'toram' is SILENTLY IGNORED by live-boot when RAM is insufficient; in
# that case the root filesystem still comes from the mapping, and removing it
# would kill the installer mid-run. The proof that toram took effect:
# /run/live/medium is a tmpfs. At the slightest doubt we give up and fall back to
# the manual instruction.
release_boot_medium(){
  local p="$1" fs dm base name holders mp disk
  fs=$(findmnt -no FSTYPE /run/live/medium 2>/dev/null || true)
  if [ -n "$fs" ] && [ "$fs" != "tmpfs" ]; then
    logx "release refused: the live system still reads the medium ($fs), toram not active"
    return 1
  fi
  command -v dmsetup >/dev/null 2>&1 || { logx "release impossible: dmsetup missing"; return 1; }

  for dm in /sys/block/dm-*; do
    [ -e "$dm/slaves/$p" ] || continue
    base=$(basename "$dm")
    name=$(cat "$dm/dm/name" 2>/dev/null)
    # A stacked mapping on top forbids removal.
    holders=$(find "$dm/holders" -mindepth 1 2>/dev/null | wc -l)
    if [ "${holders:-0}" -gt 0 ]; then
      logx "release refused: ${name:-$base} has dependants"
      return 1
    fi
    # Unmount the mapping if it is still mounted: with toram the ISO is no
    # longer used. "|| [ -n "$mp" ]": without it, output with no trailing newline
    # would DROP the last line, hence leave a mount point unmounted.
    while read -r mp || [ -n "$mp" ]; do
      [ -n "$mp" ] || continue
      umount "$mp" 2>>"$LOG" || { logx "release: $mp cannot be unmounted"; return 1; }
    done < <(findmnt -rn -S "/dev/$base" -o TARGET 2>/dev/null)
    dmsetup remove "${name:-$base}" 2>>"$LOG" \
      || { logx "release: dmsetup remove failed on ${name:-$base}"; return 1; }
    logx "boot mapping ${name:-$base} removed, /dev/$p released"
  done

  # Ventoy sometimes write-protects the device.
  disk=$(lsblk -no PKNAME "/dev/$p" 2>/dev/null | head -1 | tr -d ' ')
  [ -n "$disk" ] && { blockdev --setrw "/dev/$disk" 2>>"$LOG" || true; }
  partprobe "/dev/${disk:-$p}" 2>>"$LOG" || true
  udevadm settle 2>/dev/null || sleep 2
  return 0
}

write_log_to(){
  local p="$1" src="$2" need="$3" mp avail owned=0 rc

  # Claimed by a boot mapping? Try to release it rather than imposing an
  # unplug. If that fails, the caller returns 4 and the user gets the manual
  # instruction.
  if dm_holds "$p"; then
    release_boot_medium "$p" || true
  fi
  # TRAP (seen under Ventoy): if the partition is ALREADY mounted read-only --
  # Ventoy holds its data partition to read the ISO from it -- then
  # "mount -o rw" reuses the read-only superblock and succeeds anyway.
  # The cp then failed, and was reported as lack of space. So we detect the
  # existing mount, try to switch it back to read-write, and NEVER UNMOUNT what
  # we did not mount: the live system may depend on it.
  # We TRY first, presuming nothing: dm_holds only serves to EXPLAIN a failure
  # (code 4), never to refuse to try -- a configuration where it would work
  # anyway must not be discarded.
  mp=$(findmnt -rn -S "/dev/$p" -o TARGET 2>/dev/null | head -1)
  if [ -n "$mp" ]; then
    if ! touch "$mp/.haos-wtest" 2>/dev/null; then
      if ! mount -o remount,rw "$mp" 2>>"$LOG" || ! touch "$mp/.haos-wtest" 2>/dev/null; then
        dm_holds "$p" && { logx "log: /dev/$p claimed by device-mapper (Ventoy)"; return 4; }
        return 3
      fi
    fi
    rm -f "$mp/.haos-wtest" 2>/dev/null || true
  else
    mp=/mnt/logdest
    mkdir -p "$mp" 2>/dev/null
    if ! mount -o rw "/dev/$p" "$mp" 2>>"$LOG"; then
      dm_holds "$p" && { logx "log: /dev/$p claimed by device-mapper (Ventoy)"; return 4; }
      return 1
    fi
    owned=1
  fi

  rc=0
  avail=$(df --output=avail -k "$mp" 2>/dev/null | tail -1 | tr -d ' ')
  if [ "${avail:-0}" -lt "$need" ]; then
    rc=2
  elif cp "$src" "$mp/haos-install-$(date +%Y%m%d-%H%M).log" 2>>"$LOG"; then
    sync
  else
    rc=3                      # mounted but not writable: this is NOT "full"
  fi
  [ "$owned" -eq 1 ] && { umount "$mp" 2>/dev/null || true; }
  return $rc
}

# Tries to write the log. Prints the device used, or returns:
#   1 = no writable medium found
#   2 = medium found but no room
#   3 = medium found but not writable (mounted read-only)
#   4 = medium claimed by the boot system (Ventoy): unplug/replug
try_write_log(){
  local src="$1" part st need rc=1
  need=$(( ($(stat -c%s "$src" 2>/dev/null || echo 0) / 1024) + 64 ))   # KB + margin

  # Partitions of removable disks. TRAN belongs to the DISK, not to the
  # partition -> we first build the list of removable disks, then filter the
  # partitions by their PKNAME. HOTPLUG alone would not do: NVMe drives and
  # hot-swap SATA bays report it too, and we would then write onto an internal
  # disk. The installation stick itself offers no target: its ESP leaves only
  # ~10 KB free and the ISO9660 is read-only -- hence the reformat offer
  # (reformat_stick) as the main route.
  local usb_disks="" d
  while read -r d; do
    [ -n "$d" ] || continue
    if [ "$(lsblk -dno TRAN "/dev/$d" 2>/dev/null | tr -d ' ')" = "usb" ] \
       || [ "$(lsblk -dno RM "/dev/$d" 2>/dev/null | tr -d ' ')" = "1" ]; then
      usb_disks="$usb_disks $d"
    fi
  done < <(lsblk -dno NAME 2>/dev/null | tr -d ' ')

  local fstype pk type_ target_disk=""
  [ -n "${TARGET:-}" ] && target_disk=$(basename "$TARGET")
  while read -r part type_; do
    [ "$type_" = "part" ] || continue
    fstype=$(lsblk -no FSTYPE "/dev/$part" 2>/dev/null | tr -d ' ')
    case "$fstype" in iso9660|udf|"") continue ;; esac       # RO by design
    pk=$(lsblk -no PKNAME "/dev/$part" 2>/dev/null | head -1 | tr -d ' ')
    case " $usb_disks " in *" $pk "*) ;; *) continue ;; esac
    # Never the target disk: a die() after the flash would write into the
    # freshly installed hassos-boot.
    [ -n "$target_disk" ] && [ "$pk" = "$target_disk" ] && continue
    write_log_to "$part" "$src" "$need"; st=$?
    [ $st -eq 0 ] && { echo "/dev/$part"; return 0; }
    # We keep the most informative diagnosis: "full" or "read-only" beat "no
    # medium", which would suggest a detection failure when a medium was in fact
    # found.
    # 4 (claimed by Ventoy) is the most actionable: it takes precedence.
    case $st in 4) rc=4 ;; 2|3) [ "$rc" -eq 4 ] || rc=$st ;; esac
  done < <(lsblk -lno NAME,TYPE 2>/dev/null)

  return $rc
}

# Readable description of a partition: "/dev/sdb3 (SanDisk Ultra 32G)".
# Multiple columns are allowed here: we display, we do not read fields back.
describe_part(){
  local p pk info
  p=$(basename "$1")
  pk=$(lsblk -no PKNAME "/dev/$p" 2>/dev/null | head -1 | tr -d ' ')
  info=$(lsblk -dno VENDOR,MODEL,SIZE "/dev/${pk:-$p}" 2>/dev/null | xargs)
  if [ -n "$info" ]; then printf '/dev/%s (%s)' "$p" "$info"
  else                    printf '/dev/%s' "$p"
  fi
}
# Reformats the INSTALLATION STICK as a single FAT32 partition covering the
# whole space, then drops the log onto it.
#
# Two problems solved at once:
#   - the log lands on a SINGLE partition, hence visible everywhere; Windows 11
#     only exposes the first partition of a removable medium, which made a
#     dedicated partition added to the ISO invisible;
#   - the stick becomes reusable. Windows cannot reformat on its own a stick
#     written by Etcher (that needs diskpart in an administrator PowerShell), the
#     isohybrid layout confusing its formatting tool.
#
# 'toram' having copied the live system to RAM, the medium is no longer mounted
# and can therefore be repartitioned. We CHECK that before writing anyway: at the
# slightest doubt we give up WITHOUT ERASING ANYTHING, on a stick that may be the
# only way to try again.
# Codes: 0 = reformatted | 1 = refused by the user
#        2 = gave up BEFORE any write, the stick is intact
#        3 = failure AFTER erasing started: the stick is no longer bootable
# The 2/3 distinction is not cosmetic: it decides whether we may tell the user
# that their stick still works as an installer.
reformat_stick(){
  local dev="$1" p mnt=/mnt/newstick
  [ -n "$dev" ] || { logx "reformat impossible: boot medium not identified"; return 2; }
  [ -b "/dev/$dev" ] || { logx "reformat impossible: /dev/$dev missing"; return 2; }
  # NEVER a virtual device: under Ventoy the ISO is exposed through
  # device-mapper (/dev/dm-0), and erasing it would mean writing into the sectors
  # of the ISO file on the stick. to_physical_disk must have walked back to the
  # real disk; if it did not, we give up.
  case "$dev" in
    dm-*|loop*|md*) logx "reformat refused: $dev is a virtual device"; return 2 ;;
  esac
  # Must be a WHOLE disk, not a partition.
  [ "$(lsblk -dno TYPE "/dev/$dev" 2>/dev/null | tr -d ' ')" = "disk" ] \
    || { logx "reformat refused: $dev is not a whole disk"; return 2; }
  # Never the disk we have just installed to.
  [ -n "${TARGET:-}" ] && [ "$dev" = "$(basename "$TARGET")" ] && {
    logx "reformat refused: $dev is the installation disk"; return 2; }

  # No partition of the device may be mounted.
  for p in $(lsblk -lno NAME "/dev/$dev" 2>/dev/null); do
    if findmnt -rn -S "/dev/$p" >/dev/null 2>&1; then
      logx "reformat impossible: /dev/$p is mounted"
      return 2
    fi
  done

  # --defaultno: the action ERASES the stick, so the default button must be
  # "keep the installer". Confirming without reading must not destroy anything.
  wt_yesno "$S_WARN" "$(printf "$S_FMT_ASK" "$(describe_part "/dev/$dev")")" \
    --defaultno --yes-button "$S_FMT_YES" --no-button "$S_FMT_NO" \
    || { logx "reformat refused by the user"; return 1; }

  # ---- FROM HERE ON THE STICK IS MODIFIED: any failure returns 3, not 2. ----
  # 0x0c = FAT32 LBA, boot set, start at 1 MiB (alignment).
  wipefs -af "/dev/$dev" 2>>"$LOG" || true
  printf 'label: dos\nstart=2048, type=0c, bootable\n' \
    | sfdisk --quiet --force "/dev/$dev" 2>>"$LOG" || {
        logx "reformat: sfdisk failed, stick no longer bootable"; return 3; }
  partprobe "/dev/$dev" 2>>"$LOG" || true; udevadm settle 2>/dev/null || sleep 2

  p=$(lsblk -lno NAME,TYPE "/dev/$dev" 2>/dev/null | awk '$2=="part"{print $1; exit}')
  [ -n "$p" ] || { logx "reformat: no partition after sfdisk"; return 3; }
  # mkfs.vfat -F 32 formats beyond 32 GB, where the Windows tool refuses.
  mkfs.vfat -F 32 -n "$LOGS_LABEL" "/dev/$p" >/dev/null 2>>"$LOG" || {
      logx "reformat: mkfs.vfat failed on /dev/$p"; return 3; }

  mkdir -p "$mnt"
  mount "/dev/$p" "$mnt" 2>>"$LOG" || { logx "reformat: mounting /dev/$p impossible"; return 3; }
  cp "$LOG" "$mnt/haos-install-$(date +%Y%m%d-%H%M).log" 2>>"$LOG" || true
  sync; umount "$mnt" 2>>"$LOG" || true
  logx "stick $dev reformatted as FAT32 ($LOGS_LABEL), log copied"
  return 0
}

# Saving the log. An explicit MENU, not a chain of questions: in the previous
# version, reaching the reformat step meant answering "Give up" to the question
# about the second stick -- a button that looked like it stopped everything while
# it actually gave access to the other options. Every destination is now named
# and picked directly.
save_log(){
  local dest st choice items=()
  [ -s "$LOG" ] || return 0
  wt_yesno "$S_TITLE" "$S_LOG_ASK" || return 0

  # First automatic attempt: if a writable stick is already there, no point
  # imposing a menu.
  dest=$(try_write_log "$LOG"); st=$?
  if [ $st -eq 0 ]; then
    wt_msg "$S_TITLE" "$(printf "$S_LOG_OK" "$(describe_part "$dest")")"; return 0
  fi
  case $st in
    2) wt_msg "$S_WARN" "$S_LOG_FULL" ;;
    3) wt_msg "$S_WARN" "$S_LOG_RO" ;;
    4) wt_msg "$S_WARN" "$S_LOG_VTOY" ;;   # claimed by dm: precise instruction
  esac

  while true; do
    items=("$S_LOG_M_USB" "$S_LOG_M_USB_D")
    # Reformatting is only offered if the boot stick was identified.
    [ -n "${live_dev:-}" ] && items+=("$S_LOG_M_FMT" "$S_LOG_M_FMT_D")
    items+=("$S_LOG_M_SHOW" "$S_LOG_M_SHOW_D" "$S_LOG_M_NONE" "$S_LOG_M_NONE_D")

    choice=$(wt_menu "$S_TITLE" "$S_LOG_MENU" 4 "${items[@]}") \
             || choice="$S_LOG_M_NONE"

    case "$choice" in
      "$S_LOG_M_USB")
        whiptail --title "$S_TITLE" --infobox "$S_LOG_DETECT" 7 62
        udevadm settle 2>/dev/null || sleep 3
        partprobe 2>/dev/null || true; sleep 1
        dest=$(try_write_log "$LOG"); st=$?
        case $st in
          0) wt_msg "$S_TITLE" "$(printf "$S_LOG_OK" "$(describe_part "$dest")")"; return 0 ;;
          2) wt_msg "$S_WARN" "$S_LOG_FULL" ;;
          3) wt_msg "$S_WARN" "$S_LOG_RO" ;;
          4) wt_msg "$S_WARN" "$S_LOG_VTOY" ;;
          *) wt_msg "$S_TITLE" "$S_LOG_RETRY" ;;
        esac ;;
      "$S_LOG_M_FMT")
        reformat_stick "${live_dev:-}"
        case $? in
          0) wt_msg "$S_TITLE" "$(printf "$S_LOG_OK" "$(describe_part "/dev/$live_dev")")"; return 0 ;;
          2) wt_msg "$S_WARN" "$S_FMT_FAIL" ;;
          3) wt_msg "$S_WARN" "$S_FMT_BROKEN" ;;
        esac ;;                                  # 1 = refused, back to the menu
      "$S_LOG_M_SHOW")
        # Always available, with no medium: wt_msg switches to --scrolltext on
        # its own so that the log scrolls.
        wt_msg "$S_TITLE" "$(cat "$LOG")" ;;
      *) break ;;
    esac
  done
  wt_msg "$S_TITLE" "$(printf "$S_LOG_NONE" "$LOG")"
}

# ---------------------------------------------------------------------------
# nmcli TRAP: after a failure, a profile named after the SSID is left behind
# with the wrong password. A new "dev wifi connect ... password ..." call
# REACTIVATES that profile and IGNORES the supplied password -> the second
# attempt fails with the old one. So we delete any existing profile for that SSID.
forget_profile(){
  local ssid="$1" name
  nmcli connection delete "$ssid" >/dev/null 2>&1 || true
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if [ "$(nmcli -g 802-11-wireless.ssid connection show "$name" 2>/dev/null)" = "$ssid" ]; then
      nmcli connection delete "$name" >/dev/null 2>&1 || true
    fi
  done < <(nmcli -t -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2 ~ /wireless/ {print $1}')
}

setup_network(){
  have_net && return 0
  whiptail --title "$S_TITLE" --infobox "$S_NET_ETH" 7 62
  sleep 5; have_net && return 0

  rfkill unblock all 2>/dev/null || true
  nmcli radio wifi on 2>/dev/null || true
  sleep 2

  local wifi_if
  wifi_if=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')
  if [ -z "$wifi_if" ]; then
    local diag
    diag=$( { ip -br link 2>/dev/null; nmcli dev status 2>/dev/null;
              rfkill list 2>/dev/null; dmesg 2>/dev/null | grep -i firmware | tail -4; } \
            | cut -c1-62 | head -18 )
    wt_msg "$S_TITLE" "$(printf "$S_NET_NOWIFI" "$diag")"
  fi

  while true; do
    whiptail --title "$S_TITLE" --infobox "$S_NET_SCAN" 7 62
    nmcli dev wifi rescan 2>/dev/null || true; sleep 3

    local menu=() ssid sig sec
    while IFS=$'\t' read -r ssid sig sec; do
      [ -n "$ssid" ] || continue
      menu+=("$ssid" "$(printf 'signal %3s%%   %s' "$sig" "${sec:-open}")")
    done < <(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list 2>/dev/null \
             | awk -F: 'length($1) && !seen[$1]++ {print $1"\t"$2"\t"$3}')

    menu+=("$S_NET_RESCAN" "$S_NET_RESCAN_D")
    menu+=("$S_NET_MANUAL" "$S_NET_MANUAL_D")
    menu+=("$S_NET_ETHRETRY" "$S_NET_ETHRETRY_D")

    local choice
    choice=$(wt_menu "$S_TITLE" "$S_NET_PICK" 10 "${menu[@]}") \
      || { wt_yesno "$S_TITLE" "$S_NET_QUIT" && die "$S_CANCELLED" || continue; }

    case "$choice" in
      "$S_NET_RESCAN")    continue ;;
      "$S_NET_MANUAL")    clear; nmtui; clear; have_net && return 0 || continue ;;
      "$S_NET_ETHRETRY")  have_net && return 0 || continue ;;
    esac

    # --inputbox and not --passwordbox: blind typing plus a possibly wrongly
    # mapped keyboard = too many failures. The machine is being installed.
    local psk
    psk=$(whiptail --title "$S_TITLE" --inputbox "$(printf "$S_NET_PSK" "$choice")" 10 66 3>&1 1>&2 2>&3) || continue

    whiptail --title "$S_TITLE" --infobox "$(printf "$S_NET_CONN" "$choice")" 7 62
    forget_profile "$choice"
    local err
    if err=$(nmcli dev wifi connect "$choice" password "$psk" 2>&1) && have_net; then
      WIFI_SSID="$choice"; WIFI_PSK="$psk"   # remembered for push_wifi_config
      return 0
    fi
    wt_msg "$S_TITLE" \
      "$(printf "$S_NET_FAIL" "$choice" "$(echo "$err" | cut -c1-58 | head -3)")"
  done
}

# ---------------------------------------------------------------------------
# REQUIRES the network: over Wi-Fi, nothing is reachable before setup_network.
resolve_version(){
  whiptail --title "$S_TITLE" --infobox "$S_VER_FETCH" 7 66

  # Source of truth: the Supervisor's stable channel. The GitHub API ignores
  # channel demotions (a stable release can be withdrawn afterwards,
  # cf. HAOS 18.0 and the RPi/Yellow firmware) and would then offer a version
  # Home Assistant no longer considers current.
  # jq rather than grep: the board key exists ALSO under "homeassistant"
  # (HA Core version) -> a grep would return that value.
  HAOS_VERSION=$(curl -fsSL --max-time 15 https://version.home-assistant.io/stable.json 2>>"$LOG" \
    | jq -r --arg b "$HAOS_BOARD" '.hassos[$b] // empty' 2>>"$LOG" || true)
  [[ "$HAOS_VERSION" =~ ^[0-9]+(\.[0-9]+)+$ ]] || HAOS_VERSION=""
  VER_SRC="stable channel"

  # Fallback: the GitHub API, which excludes pre-releases (RC) by construction.
  # Deliberately left on grep: if jq disappeared from the package list, the
  # previous step would return empty and this path would keep working.
  if [ -z "$HAOS_VERSION" ]; then
    HAOS_VERSION=$(curl -fsSL --max-time 15 \
      https://api.github.com/repos/home-assistant/operating-system/releases/latest \
      2>>"$LOG" | grep -oP '"tag_name":\s*"\K[^"]+' || true)
    [[ "$HAOS_VERSION" =~ ^[0-9]+(\.[0-9]+)+$ ]] || HAOS_VERSION=""
    VER_SRC="GitHub API fallback"
    logx "stable channel unreachable or silent, falling back to the GitHub API"
  fi

  # No hard-coded version as a last resort: it would only help if both sources
  # were unreachable WHILE downloading the image from GitHub works -- a
  # near-empty scenario. It would however mean editing the script and rebuilding
  # the ISO for every HAOS release. Plain failure.
  [ -n "$HAOS_VERSION" ] || die "$S_VER_FAIL"

  IMG_URL="https://github.com/home-assistant/operating-system/releases/download/${HAOS_VERSION}/haos_${HAOS_BOARD}-${HAOS_VERSION}.img.xz"
  logx "version resolved: $HAOS_VERSION (board $HAOS_BOARD, source $VER_SRC)"
  logx "image: $IMG_URL"
  curl -fsI --max-time 15 "$IMG_URL" >/dev/null 2>>"$LOG" \
    || die "$(printf "$S_VER_NOIMG" "$HAOS_VERSION" "$IMG_URL")"
}

# ---------------------------------------------------------------------------
pick_disk(){
  local menu=() name size model tran vendor rm_ hp tag
  # whiptail cannot colour a menu item -> textual marking at the front.
  # No eval on lsblk output: a MODEL field containing a quote would break the
  # parsing. One column at a time, otherwise an empty field shifts the following
  # ones when read back.
  while read -r name; do
    [ -n "$name" ] || continue
    [ -n "$live_dev" ] && [ "$name" = "$live_dev" ] && continue   # never the boot medium
    # Belt and braces: any disk carrying an iso9660 (itself or one of its
    # partitions) is an installation medium, never a target. Covers the writes
    # where the LABEL would not be the expected one (dd of another ISO).
    lsblk -no FSTYPE "/dev/$name" 2>/dev/null | grep -qx iso9660 && continue
    # Ventoy stick: it does NOT carry an iso9660 (the ISO is a file on its exFAT
    # partition, exposed via device-mapper), so the previous test let it through.
    # Its 2nd partition carries the VTOYEFI label: a reliable signal.
    lsblk -no LABEL "/dev/$name" 2>/dev/null | grep -qix 'VTOYEFI' && continue

    size=$(lsblk -dno SIZE    "/dev/$name" 2>/dev/null | xargs)
    model=$(lsblk -dno MODEL  "/dev/$name" 2>/dev/null | xargs)
    vendor=$(lsblk -dno VENDOR "/dev/$name" 2>/dev/null | xargs)
    tran=$(lsblk -dno TRAN    "/dev/$name" 2>/dev/null | xargs)
    rm_=$(lsblk -dno RM       "/dev/$name" 2>/dev/null | xargs)
    hp=$(lsblk -dno HOTPLUG   "/dev/$name" 2>/dev/null | xargs)

    tag=""
    if [ "${rm_:-0}" = "1" ] || [ "${hp:-0}" = "1" ] || [ "$tran" = "usb" ]; then
      case "$UI_LANG" in
        fr) tag="[!! USB / EXTERNE !!] " ;;
        de) tag="[!! USB / EXTERN !!] " ;;
        da) tag="[!! USB / EKSTERN !!] " ;;
        *)  tag="[!! USB / EXTERNAL !!] " ;;
      esac
    fi
    menu+=("/dev/$name" "$(printf '%s%-9s %-5s %s' "$tag" "${size:-?}" "${tran:-?}" \
           "$(echo "$vendor ${model:-?}" | xargs)")")
  done < <(lsblk -dno NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}')

  [ ${#menu[@]} -gt 0 ] || die "$S_DISK_NONE"

  TARGET=$(wt_menu "$S_TITLE" "$S_DISK_PICK" 8 "${menu[@]}") \
    || die "$S_CANCELLED"

  # 32 GB: below that threshold dd would die with "No space left" AFTER erasing.
  local bytes gb
  bytes=$(blockdev --getsize64 "$TARGET" 2>/dev/null || echo 0)
  gb=$(( bytes / 1000000000 ))
  if [ "$gb" -lt 32 ]; then
    wt_yesno "$S_WARN" "$(printf "$S_DISK_SMALL" "$TARGET" "$gb")" \
      --yes-button "$S_STOP" --no-button "$S_GOON" && die "$S_STOPPED"
  fi

  local content
  content=$(lsblk -no NAME,SIZE,FSTYPE,LABEL "$TARGET" 2>/dev/null | sed 's/^/   /')
  # --defaultno: the button that wins on a stray Enter must not erase the disk.
  wt_yesno "$S_CONFIRM_T" "$(printf "$S_DISK_CONFIRM" "$TARGET" "$content")" \
    --defaultno || die "$S_CANCELLED"
  logx "target confirmed: $(describe_part "$TARGET"), ${gb} GB"
  logx "live medium excluded: ${live_dev:-<not identified>}"
}

# ---------------------------------------------------------------------------
flash(){
  whiptail --title "$S_TITLE" --infobox "$(printf "$S_PREP" "$TARGET")" 7 62
  wipefs -af "$TARGET" 2>>"$LOG" || true
  dd if=/dev/zero of="$TARGET" bs=1M count=16 conv=fsync 2>>"$LOG" || true
  local bytes seek; bytes=$(blockdev --getsize64 "$TARGET" 2>/dev/null || echo 0); seek=$(( bytes/1048576 - 16 ))
  (( seek > 0 )) && dd if=/dev/zero of="$TARGET" bs=1M seek="$seek" count=16 conv=fsync 2>>"$LOG" || true

  local dl
  dl=$(curl -fsSLI "$IMG_URL" 2>>"$LOG" \
       | awk 'BEGIN{IGNORECASE=1}/^content-length/{v=$2}END{gsub(/\r/,"",v);print v}')
  [[ "$dl" =~ ^[0-9]+$ ]] && (( dl > 1000000 )) || dl=560000000     # fallback if the header is missing

  # whiptail's stdout is forced onto /dev/tty: otherwise the process substitution
  # inherits the pipe to xz and injects the terminal codes into it.
  set -o pipefail
  local rc
  {
    # --speed-limit/--speed-time: without them, a network drop left curl waiting
    # on the TCP timers, 'pv -n' re-emitting the last percentage, and the gauge
    # frozen indefinitely -- the user could not tell "slow" from "dead". Below
    # 1 KB/s for 30 s, curl gives up.
    # No --retry here: without -C - the resume starts from zero and re-injects
    # the bytes into the xz stream, which corrupts it; and -C - is unusable on a
    # pipe, curl being unable to seek in it.
    curl -fSL --speed-limit 1024 --speed-time 30 "$IMG_URL" 2>>"$LOG" \
      | pv -n -s "$dl" 2> >(whiptail --title "$S_TITLE" --gauge \
            "$(printf "$S_WRITING" "$HAOS_VERSION")" 9 72 0 >/dev/tty) \
      | xz -dc 2>>"$LOG" \
      | tee >(sha256sum | cut -d' ' -f1 > /tmp/haos-img.sha256) \
            >(wc -c > /tmp/haos-img.size) \
      | dd of="$TARGET" bs=4M conv=fsync 2>>"$LOG"
  }
  rc=$?
  sync; wait 2>/dev/null || true
  logx "writing finished on $TARGET (code $rc)"

  if [ $rc -ne 0 ]; then
    die "$(printf "$S_FAIL" "$rc" "$(tail -n 10 "$LOG" 2>/dev/null | cut -c1-66)" "$LOG")"
  fi
}

# ---------------------------------------------------------------------------
# xz already validates the integrity of the DOWNLOAD (checksums of the format).
# Here we validate the WRITE: failing sector, end-of-life SSD, doubtful cable.
verify(){
  local expect size actual i
  # These two files are written by flash()'s process substitutions, which 'wait'
  # does not guarantee to wait for on every bash version. A partial file would
  # give a truncated checksum, hence a FALSE failing-disk alert: we wait briefly
  # until complete values are available.
  for i in {1..20}; do
    expect=$(tr -d ' \n' < /tmp/haos-img.sha256 2>/dev/null)
    size=$(tr -d ' \n' < /tmp/haos-img.size 2>/dev/null)
    [[ "$expect" =~ ^[0-9a-f]{64}$ ]] && [[ "$size" =~ ^[0-9]+$ ]] && break
    sleep 1
  done

  if ! [[ "$size" =~ ^[0-9]+$ ]] || ! [[ "$expect" =~ ^[0-9a-f]{64}$ ]]; then
    logx "verification impossible: reference checksum or size unavailable"
    wt_msg "$S_TITLE" "$S_VFY_SKIP"; return 0
  fi

  wt_yesno "$S_TITLE" \
    "$(printf "$S_VFY_ASK" "$(numfmt --to=iec "$size" 2>/dev/null || echo "$size")" "$TARGET")" \
    || return 0

  # Flush the cache: otherwise we read back RAM, not the disk -> useless check.
  sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

  actual=$(head -c "$size" "$TARGET" 2>>"$LOG" \
    | pv -n -s "$size" 2> >(whiptail --title "$S_TITLE" --gauge "$S_VFY_RUN" 8 68 0 >/dev/tty) \
    | sha256sum | cut -d' ' -f1)

  if [ "$actual" = "$expect" ]; then
    logx "verification OK: disk sha256 matches the image ($expect)"
    wt_msg "$S_TITLE" "$(printf "$S_VFY_OK" "${expect:0:32}")"
  else
    logx "VERIFICATION FAILED: expected $expect, read $actual"
    wt_msg "$S_WARN" \
      "$(printf "$S_VFY_KO" "${expect:0:24}" "${actual:0:24}")"
    die "$S_VFY_ABORT"
  fi
}

# ---------------------------------------------------------------------------
# Locates the keyfile of a connection. nmcli exposes connection.filename in
# recent versions; otherwise we find it by its UUID, the location being
# deterministic.
nm_profile_path(){
  local uuid="$1" f
  f=$(nmcli -g connection.filename connection show "$uuid" 2>/dev/null | head -1)
  [ -f "$f" ] && { printf '%s' "$f"; return 0; }
  f=$(grep -ls "^uuid=$uuid" /etc/NetworkManager/system-connections/* 2>/dev/null | head -1)
  [ -f "$f" ] && { printf '%s' "$f"; return 0; }
  return 1
}

# Hand-written profile, used ONLY as a fallback. key-mgmt is derived from the
# encryption actually detected: forcing it to wpa-psk (previous behaviour)
# produced a profile that does not work with pure WPA3 or on an open network.
# UUID random but fixed in the file: otherwise the IP changes on every boot.
# UNIX line endings (LF) mandatory.
write_fallback_profile(){
  local dst="$1" km="$2" hidden=""
  nmcli -g 802-11-wireless.hidden connection show "$WIFI_SSID" 2>/dev/null | grep -qi yes \
    && hidden="hidden=true"
  {
    printf '[connection]\n'
    printf 'id=%s\n' "$WIFI_SSID"
    printf 'uuid=%s\n' "$(cat /proc/sys/kernel/random/uuid)"
    printf 'type=802-11-wireless\n\n'
    printf '[802-11-wireless]\n'
    printf 'mode=infrastructure\n'
    printf 'ssid=%s\n' "$WIFI_SSID"
    [ -n "$hidden" ] && printf '%s\n' "$hidden"
    # Open network: NO security section, otherwise NM rejects the profile.
    if [ -n "$km" ]; then
      printf '\n[802-11-wireless-security]\n'
      printf 'key-mgmt=%s\n' "$km"
      [ "$km" = "wpa-psk" ] && printf 'auth-alg=open\n'
      printf 'psk=%s\n' "$WIFI_PSK"
    fi
    printf '\n[ipv4]\nmethod=auto\n\n'
    printf '[ipv6]\naddr-gen-mode=stable-privacy\nmethod=auto\n'
  } > "$dst" 2>>"$LOG"
}

# Wi-Fi installation: HAOS forgets everything on first boot and waits for a
# network. So we drop a NetworkManager profile into CONFIG/network/my-network of
# the hassos-boot partition (FAT), which HAOS imports at startup.
#
# We COPY the profile NM has already written, instead of rebuilding it: its
# key-mgmt is right by construction (WPA2, pure WPA3/SAE, OWE, WEP, open) and it
# carries the hidden SSID, the static IP and everything the user configured. The
# reason once given for rewriting it -- "interface-name locks the profile to the
# live system's card" -- is fixed directly by emptying that property.
# This also covers the nmtui path, which injected NOTHING before: the guard was
# on WIFI_SSID, never set by that route.
#
# Return codes:
#   0 = injected | 1 = technical failure | 2 = deliberate refusal | 3 = nothing to do
push_wifi_config(){
  local uuid part src km mnt=/mnt/hassos-boot dst
  # Active Wi-Fi connection, whatever way it was created.
  uuid=$(active_wifi_uuid)
  [ -n "$uuid" ] || return 3                   # wired installation: nothing to do

  # nmtui path: WIFI_SSID was never set. We recover it for the DISPLAY of the
  # final message (the log itself does not carry it).
  [ -n "${WIFI_SSID:-}" ] \
    || WIFI_SSID=$(nmcli -g 802-11-wireless.ssid connection show "$uuid" 2>/dev/null | head -1)

  # hassos-boot = 1st partition of the written image (label hassos-boot, else p1)
  partprobe "$TARGET" 2>>"$LOG" || true; sleep 1
  part=$(lsblk -nro NAME,LABEL "$TARGET" 2>/dev/null | awk '$2=="hassos-boot"{print $1; exit}')
  [ -n "$part" ] || part=$(lsblk -nro NAME "$TARGET" 2>/dev/null | sed -n '2p')
  [ -n "$part" ] || return 1

  # Detach the profile from the live system's interface BEFORE reading it: NM
  # then rewrites the file on disk. Without that HAOS would not activate it on
  # any card.
  nmcli connection modify "$uuid" connection.interface-name "" >/dev/null 2>&1 || true

  km=$(nmcli -g 802-11-wireless-security.key-mgmt connection show "$uuid" 2>/dev/null)
  src=$(nm_profile_path "$uuid") || src=""

  # Deliberate refusal: a profile referencing certificate FILES cannot work under
  # HAOS, those paths not existing there. Better to write nothing than to promise
  # a network that will never come up. A PEAP/MSCHAPv2 without a certificate, with
  # the password stored, copies over and works: do not refuse it.
  if [ -n "$src" ] && grep -qE '^[[:space:]]*(ca-cert|client-cert|private-key|ca-path)=' "$src"; then
    logx "Wi-Fi profile NOT injected: 802.1X with certificates, files absent under HAOS"
    return 2
  fi

  mkdir -p "$mnt"
  mount "/dev/$part" "$mnt" 2>>"$LOG" || return 1
  mkdir -p "$mnt/CONFIG/network"
  dst="$mnt/CONFIG/network/my-network"

  # The secret must be IN the file: if it is managed by an agent, the copied
  # profile would be mute on the HAOS side -> we switch to the fallback.
  local copied=1
  if [ -n "$src" ]; then
    case "$km" in
      wpa-psk|sae) grep -q '^[[:space:]]*psk=' "$src" || src="" ;;
    esac
  fi
  if [ -n "$src" ]; then
    # Remove keys specific to THIS machine: interface-name (belt and braces if
    # the modify did not take) and permissions, which would tie the profile to a
    # user account that does not exist under HAOS.
    grep -vE '^[[:space:]]*(interface-name|permissions)=' "$src" > "$dst" 2>>"$LOG" && copied=0
  fi

  if [ "$copied" -ne 0 ]; then
    # Fallback: requires the guided walkthrough (SSID and PSK known).
    if [ -z "${WIFI_SSID:-}" ] || [ -z "${WIFI_PSK:-}" ]; then
      logx "Wi-Fi profile NOT injected: unreadable NM profile and no stored secret"
      sync; umount "$mnt" 2>>"$LOG" || true
      return 2
    fi
    case "$km" in
      none|wpa-eap|wpa-eap-suite-b-192)
        # WEP and enterprise: do not guess a format we do not master.
        logx "Wi-Fi profile NOT injected: key-mgmt=$km not handled by the fallback"
        sync; umount "$mnt" 2>>"$LOG" || true
        return 2 ;;
    esac
    logx "Wi-Fi profile: falling back to a hand-written profile (key-mgmt=${km:-none})"
    write_fallback_profile "$dst" "$km"
  else
    logx "Wi-Fi profile: NetworkManager profile copied (key-mgmt=${km:-none})"
  fi

  # Check BEFORE unmounting: after umount the mount point is empty and the test
  # would always be false -- that is what made it announce success even when
  # writing the keyfile had failed.
  local ok=1
  [ -s "$mnt/CONFIG/network/my-network" ] && ok=0
  sync; umount "$mnt" 2>>"$LOG" || true
  return $ok
}

# ---------------------------------------------------------------------------
finalize(){
  # Wi-Fi installation: inject the profile so that HAOS reconnects on its own.
  # No guard on WIFI_SSID any more: push_wifi_config detects the active Wi-Fi
  # connection itself and exits cleanly on a wired install. That is what covers
  # nmtui.
  # Logs the result without the SSID: the SUCCESS of the injection is what
  # matters for a diagnosis, not the network name.
  local wifi_rc
  push_wifi_config; wifi_rc=$?
  case $wifi_rc in
    3) : ;;                                    # wired: nothing to say
    0) logx "Wi-Fi profile injected into CONFIG/network of hassos-boot"
       wt_msg "$S_TITLE" "$(printf "$S_WIFI_PUSH" "${WIFI_SSID:-Wi-Fi}")" ;;
    2) wt_msg "$S_WARN" "$S_WIFI_PUSH_SKIP" ;; # deliberate refusal, already logged
    *) logx "FAILED to inject the Wi-Fi profile: HAOS will boot with no network"
       wt_msg "$S_WARN" "$S_WIFI_PUSH_FAIL" ;;
  esac

  # The image already contains \EFI\BOOT\bootx64.efi; safety net for fussy
  # firmwares.
  if command -v efibootmgr >/dev/null && [ -d /sys/firmware/efi ]; then
    # Purge the entries left by previous installations on this same disk
    # (otherwise efibootmgr --create adds one more on every attempt).
    local partuuid bootnum
    for partuuid in $(lsblk -no PARTUUID "$TARGET" 2>>"$LOG"); do
      [ -n "$partuuid" ] || continue
      while read -r bootnum; do
        [ -n "$bootnum" ] && efibootmgr -b "$bootnum" -B >/dev/null 2>>"$LOG" || true
      done < <(efibootmgr -v 2>/dev/null \
        | grep -i "$partuuid" \
        | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p')
    done
    efibootmgr --create --disk "$TARGET" --part 1 \
      --label "HAOS" --loader '\EFI\BOOT\bootx64.efi' >/dev/null 2>&1 || true
    logx "UEFI entry 'HAOS' recreated on $TARGET"
  fi

  # Offer the reformat BEFORE asking for the stick to be removed: this is the
  # last moment it is still plugged in. We only announce the result if it really
  # happened, otherwise the message would lie.
  logx "installation completed successfully on $TARGET"
  local logmsg="" fmt_rc=1
  # Only when the boot stick was identified: otherwise reformat_stick can only
  # answer "impossible", which would be announced as a failure.
  [ -n "${live_dev:-}" ] && { reformat_stick "$live_dev"; fmt_rc=$?; }
  case $fmt_rc in
    0) logmsg="$S_DONE_LOG" ;;
    2) wt_msg "$S_WARN" "$S_FMT_FAIL" ;;     # stick intact
    3) wt_msg "$S_WARN" "$S_FMT_BROKEN" ;;   # stick no longer bootable: say it
                                             # 1 = deliberate refusal, nothing to say
  esac

  # 'toram' copied the live system to RAM: the stick is no longer used, so we can
  # ask for it to be removed NOW. The reboot then goes straight into HAOS, with
  # no risk of restarting the installer or removing the stick too early.
  wt_msg "$S_TITLE" "$(printf "$S_DONE" "$TARGET")$logmsg"
  clear; reboot
}

# ---------------------------------------------------------------------------
HAOS_BOARD="generic-x86-64"   # stable channel key AND image name: keep in step
# ISO_LABEL is set by build-iso.sh (--iso-volume): keep both files in step. It is
# used to recognise the boot medium, 'toram' having replaced /run/live/medium
# with a tmpfs. LOGS_LABEL is the label given to the stick if the user accepts
# its reformat at the end of the installation.
ISO_LABEL="HAOS Installer"
LOGS_LABEL="HAOS_LOGS"
HAOS_VERSION=""
VER_SRC=""                    # source chosen for the version: traced in the log
IMG_URL=""
TARGET=""
WIFI_SSID=""
WIFI_PSK=""
# Disk of the live system, to be excluded from the targets. TRAP: 'toram' (see
# --bootappend-live in build-iso.sh) copies the medium to RAM and replaces
# /run/live/medium with a tmpfs -- findmnt therefore returns "tmpfs" there and not
# a device. So we identify the medium by the LABEL that build-iso.sh set
# (--iso-volume), walking back to the parent disk if the match falls on a
# partition.
# Walks back from a device name to the PHYSICAL DISK carrying it.
# Essential under Ventoy: it exposes not the stick's partition but a
# device-mapper device (/dev/dm-0) whose content is the ISO. So it is dm-0 that
# blkid finds, a name matching no disk -- pick_disk's exclusion did not apply and
# THE VENTOY STICK WAS OFFERED AS AN INSTALLATION TARGET. /sys/block/dm-N/slaves/
# gives the underlying device.
to_physical_disk(){
  local n s pk
  n=$(basename "${1:-}")
  [ -n "$n" ] || return 1
  case "$n" in
    dm-*|md*)
      for s in "/sys/block/$n/slaves/"*; do
        [ -e "$s" ] || continue
        # Recursive: a dm stacked on dm is still possible.
        to_physical_disk "$(basename "$s")" && return 0
      done
      return 1 ;;
    loop*)
      # The backing file does not say which disk it lives on: we give up rather
      # than guess.
      return 1 ;;
  esac
  pk=$(lsblk -no PKNAME "/dev/$n" 2>/dev/null | head -1 | tr -d ' ')
  printf '%s' "${pk:-$n}"
}

resolve_live_dev(){
  local hit d src
  hit=$(blkid -L "$ISO_LABEL" 2>/dev/null)
  if [ -n "$hit" ]; then
    d=$(to_physical_disk "$hit") && [ -n "$d" ] && { printf '%s' "$d"; return 0; }
  fi
  # Historical fallback: valid if 'toram' ever disappears from bootappend.
  src=$(findmnt -no SOURCE /run/live/medium 2>/dev/null || true)
  case "$src" in
    /dev/*) to_physical_disk "$src" || printf '' ;;
    *)      printf '' ;;
  esac
}
live_dev=$(resolve_live_dev)

set_strings                 # EN defaults, replaced by the choice on screen 1
choose_lang_keyboard
# Requirements state in the log: it is the first thing to look at when HAOS does
# not boot after an otherwise successful installation.
logx "installer started -- language $UI_LANG, board $HAOS_BOARD"
logx "boot: $(boot_status) | Secure Boot: $(secureboot_status)"
STEP="1/6"                  # progress marker shown in every window title
wt_msg "$S_TITLE" \
  "$(printf "$S_WELCOME" "$(boot_status)" "$(secureboot_status)")"
STEP="2/6"
setup_network
log_active_net              # after setup_network: covers all of its exit points
STEP="3/6"
resolve_version             # REQUIRES the network: must stay after setup_network
STEP="4/6"
pick_disk
STEP="5/6"
flash
verify
STEP="6/6"
finalize
