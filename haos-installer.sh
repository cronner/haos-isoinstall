#!/bin/bash
# haos-installer.sh — Guided Home Assistant OS installer (bare metal).
#
# Whiptail screens, assisted Wi-Fi, disk selection, verification by read-back.
# Started at boot of a Debian live system. 14 languages, chosen on screen 1.
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
  S_STAGE_ASK="Pas assez de mémoire libre pour garder l'image en RAM (%s).\nAucun support inscriptible avec autant d'espace libre n'a été trouvé.\nBranche une clé USB ou un disque externe, puis choisis Réessayer : l'image y est téléchargée et vérifiée AVANT que quoi que ce soit soit effacé.\n\"Écrire en un seul passage\" efface au contraire le disque cible d'abord : si le réseau tombe ensuite, il reste un disque vide."
  S_STAGE_INFO="Pas assez de mémoire pour placer l'image en RAM.\nElle est téléchargée vers :\n%s\nRien n'est écrit sur le disque cible avant que le fichier soit complet et vérifié, et il en est effacé ensuite."
  S_STAGE_RETRY="Réessayer"
  S_STAGE_STREAM="Écrire en un seul passage"
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
  S_SRC_ASK="D'où doit venir l'image ?\n\nLe téléchargement demande une connexion Internet.\nUne image sur clé USB ne demande aucun réseau."
  S_SRC_DL="Télécharger la dernière version"
  S_SRC_USE="Utiliser une image sur clé USB"
  S_IMG_SCAN="Recherche d'images Home Assistant OS sur les\nclés connectées..."
  S_IMG_NONE="Aucune image utilisable trouvée.\n\nLe fichier doit s'appeler\n  haos_generic-x86-64-<version>.img.xz\n\nFichiers trouvés mais inutilisables ici :\n%s\n\nBranchez une clé contenant la bonne image, ou\nrevenez en arrière pour la télécharger."
  S_IMG_PICK="Quelle image faut-il écrire sur le disque ?"
  S_IMG_CHECK="Vérification des sommes .xz de l'image..."
  S_IMG_BAD="Cette image n'a pas pu être vérifiée :\n%s\n\n%s\n\nElle est abîmée, incomplète, ou ce n'est pas\nvraiment un fichier .img.xz. Rien n'a été écrit\nsur aucun disque."
  S_LAN_ASK="Aucune connexion réseau.\n\nBranchez un câble Ethernet (LAN) sur le PC, puis choisissez\nRéessayer.\n\nSans réseau, l'image ne peut pas être téléchargée.\nRien n'a encore été écrit sur aucun disque."
  S_LAN_RETRY="Réessayer"
  S_LAN_WIFI="Utiliser le Wi-Fi"
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
  S_DISK_CONFIRM="Le disque %s va être ENTIÈREMENT EFFACÉ.\n\nContenu actuel détecté :\n%s\n\nTapez YES (en majuscules) pour l'effacer et installer\nHome Assistant OS.\nToute autre réponse arrête tout, sans rien effacer."
  S_CONFIRM_T="⚠  DERNIÈRE CONFIRMATION"
  S_STOP="Arrêter (recommandé)"
  S_GOON="Continuer quand même"
  S_STOPPED="Arrêté avant toute modification."
  S_PREP="Préparation du disque %s..."
  S_WRITING="Téléchargement de HAOS %s.\nNe pas éteindre le PC."
  S_WRITE_HEAD="Écriture de l'image sur %s.\nN'éteignez pas le PC."
  S_DL_CHECK="Vérification de l'image téléchargée..."
  S_DL_RESUME="Reprise du téléchargement : %s sur %s déjà sur le disque."
  S_DL_RETRY="Le téléchargement s'est arrêté (code curl %s).\n\nDernières lignes du journal :\n%s\n\nReprendre là où il s'est arrêté ?"
  S_DL_ABORT="Le téléchargement n'a pas abouti.\n\nRIEN N'A ÉTÉ ÉCRIT : le disque est exactement dans\nson état d'origine, son contenu est toujours là.\n\nDétail :\n%s\n\nJournal complet : %s"
  S_DL_BAD="L'image téléchargée est corrompue (ses sommes de\ncontrôle .xz ne correspondent pas) — deux fois de suite.\n\nRIEN N'A ÉTÉ ÉCRIT : le disque est intact.\nCela désigne le réseau ou un proxy de cache, pas le disque.\n\nDétail :\n%s\n\nJournal complet : %s"
  S_DISK_HA="⚠  Ce disque contient déjà une installation de Home\n   Assistant (hassos-boot / hassos-data détectés).\n   L'effacer détruit ta configuration, tes add-ons\n   et ton historique."
  S_FMT_TYPE="Tapez YES pour reformater la clé.\nToute autre réponse la laisse telle quelle."
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
  S_FMT_FAIL="La clé n'a pas pu être reformatée.\n\nRien n'a été touché : elle reste utilisable comme\ninstallateur. Le détail figure dans le journal."
  S_FMT_BROKEN="Le reformatage de la clé a échoué en cours de route.\n\n⚠  La clé n'est plus amorçable : il faudra la regraver pour\ns'en resservir comme installateur.\n\nL'installation de Home Assistant sur le disque n'est pas\nconcernée, elle est terminée."
  S_DONE="Installation terminée.\n\nHome Assistant OS est installé sur %s.\n\n➜ RETIRE LA CLÉ USB MAINTENANT, avant de valider.\n  (l'installateur tourne en mémoire : la clé ne sert plus)\n\nÀ SUIVRE :\n 1. Valide ci-dessous : le PC redémarre sur Home Assistant.\n 2. Garde le câble réseau branché.\n 3. Patiente 2 à 5 minutes (premier démarrage).\n 4. Depuis un autre appareil :  http://homeassistant.local"
  S_UNAT_ACTIVE="Installation sans surveillance.\n\nFichier de configuration : %s\nLangue : %s\n\nAucune question ne sera posée."
  S_UNAT_NOWIPE="Installation sans surveillance refusée.\n\nWIPE=yes manque dans :\n%s\n\nRien n'a été modifié."
  S_UNAT_NODISK="Installation sans surveillance refusée.\n\nDISK=%s n'est pas un disque utilisable ici.\n\nRien n'a été modifié."
  S_UNAT_MULTI="Installation sans surveillance refusée.\n\n%s disques utilisables trouvés :\n%s\n\nIndique DISK= pour l'un d'eux dans le fichier de\nconfiguration. Rien n'a été modifié."
  S_UNAT_NONET="Installation sans surveillance en échec.\n\nPas de réseau et pas d'image sur une clé :\nrien ne peut être téléchargé.\n\nRien n'a été modifié."
  S_UNAT_NOSTAGE="Installation sans surveillance refusée.\n\nPas assez de RAM libre pour l'image (%s), et aucun\nsupport inscriptible pour la stocker.\n\nAjoute STREAM=yes pour accepter d'effacer le disque\navant la vérification du téléchargement.\nRien n'a été écrit."
  S_UNAT_OFF_REBOOT="Installation terminée.\n\nHome Assistant OS est installé sur %s.\n\nRetire la clé USB maintenant.\nLe PC redémarre dans 15 secondes."
  S_UNAT_OFF_HALT="Installation terminée.\n\nHome Assistant OS est installé sur %s.\n\nRetire la clé USB maintenant.\nLe PC s'éteint dans 15 secondes."
  S_UNAT_FAIL="\n\nLe journal s'affiche ici et est enregistré dans\n%s.\n\nLe PC s'éteint dans 20 secondes."
;;
de)
  S_STAGE_ASK="Zu wenig freier Arbeitsspeicher, um das Image im RAM zu halten (%s).\nEs wurde kein beschreibbares Medium mit so viel freiem Platz gefunden.\nSteck einen USB-Stick oder eine externe Festplatte an und wähle Erneut versuchen: das Image wird dorthin geladen und geprüft, BEVOR etwas gelöscht wird.\n\"In einem Durchgang schreiben\" löscht dagegen zuerst die Zieldiskette: bricht danach das Netz weg, bleibt eine leere Platte."
  S_STAGE_INFO="Zu wenig Arbeitsspeicher, um das Image im RAM abzulegen.\nEs wird geladen nach:\n%s\nAuf die Zieldiskette wird nichts geschrieben, bevor die Datei vollständig und geprüft ist; danach wird sie dort wieder gelöscht."
  S_STAGE_RETRY="Erneut versuchen"
  S_STAGE_STREAM="In einem Durchgang schreiben"
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
  S_SRC_ASK="Woher soll das Image kommen?\n\nHerunterladen braucht eine Internetverbindung.\nEin Image auf einem USB-Stick braucht kein Netz."
  S_SRC_DL="Neueste Version herunterladen"
  S_SRC_USE="Image von einem USB-Stick verwenden"
  S_IMG_SCAN="Suche nach Home Assistant OS-Images auf den\nangeschlossenen Sticks..."
  S_IMG_NONE="Kein brauchbares Image gefunden.\n\nDie Datei muss so heißen:\n  haos_generic-x86-64-<version>.img.xz\n\nGefundene, hier unbrauchbare Dateien:\n%s\n\nStecke einen Stick mit dem richtigen Image ein,\noder gehe zurück und lade es herunter."
  S_IMG_PICK="Welches Image soll auf die Platte geschrieben werden?"
  S_IMG_CHECK="Prüfe die .xz-Prüfsummen des Images..."
  S_IMG_BAD="Dieses Image konnte nicht geprüft werden:\n%s\n\n%s\n\nEs ist beschädigt, unvollständig oder kein\nechtes .img.xz. Auf keine Platte wurde etwas\ngeschrieben."
  S_LAN_ASK="Keine Netzwerkverbindung.\n\nStecke ein Ethernet-(LAN-)Kabel in den PC und wähle dann\nErneut versuchen.\n\nOhne Netz kann das Image nicht geladen werden.\nAuf keine Platte wurde bisher geschrieben."
  S_LAN_RETRY="Erneut versuchen"
  S_LAN_WIFI="Stattdessen WLAN"
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
  S_DISK_CONFIRM="Die Platte %s wird KOMPLETT GELÖSCHT.\n\nErkannter aktueller Inhalt:\n%s\n\nTippe YES (in Großbuchstaben), um sie zu löschen und\nHome Assistant OS zu installieren.\nJede andere Antwort bricht hier ab, ohne etwas zu löschen."
  S_CONFIRM_T="⚠  LETZTE BESTÄTIGUNG"
  S_STOP="Abbrechen (empfohlen)"
  S_GOON="Trotzdem weitermachen"
  S_STOPPED="Vor jeder Änderung abgebrochen."
  S_PREP="Platte %s wird vorbereitet..."
  S_WRITING="HAOS %s wird heruntergeladen.\nSchalte den PC nicht aus."
  S_WRITE_HEAD="Image wird auf %s geschrieben.\nSchalte den PC nicht aus."
  S_DL_CHECK="Heruntergeladenes Image wird geprüft..."
  S_DL_RESUME="Download wird fortgesetzt: %s von %s bereits auf der Platte."
  S_DL_RETRY="Der Download wurde unterbrochen (curl-Code %s).\n\nLetzte Protokollzeilen:\n%s\n\nDort fortsetzen, wo er abgebrochen ist?"
  S_DL_ABORT="Der Download wurde nicht abgeschlossen.\n\nES WURDE NICHTS GESCHRIEBEN: die Platte ist genau\nwie vorher, ihr Inhalt ist noch da.\n\nDetails:\n%s\n\nVollständiges Protokoll: %s"
  S_DL_BAD="Das heruntergeladene Image ist beschädigt (die\n.xz-Prüfsummen passen nicht) — zweimal hintereinander.\n\nES WURDE NICHTS GESCHRIEBEN: die Platte ist unberührt.\nDas deutet auf das Netzwerk oder einen Cache-Proxy hin,\nnicht auf die Platte.\n\nDetails:\n%s\n\nVollständiges Protokoll: %s"
  S_DISK_HA="⚠  Auf dieser Platte liegt bereits eine Home-Assistant-\n   Installation (hassos-boot / hassos-data gefunden).\n   Löschen vernichtet Konfiguration, Add-ons und Verlauf."
  S_FMT_TYPE="Tippe YES, um den Stick neu zu formatieren.\nJede andere Antwort lässt ihn unverändert."
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
  S_FMT_FAIL="Der Stick konnte nicht neu formatiert werden.\n\nNichts wurde verändert: er bleibt als Installer nutzbar.\nDetails stehen im Protokoll."
  S_FMT_BROKEN="Das Neuformatieren des Sticks ist unterwegs fehlgeschlagen.\n\n⚠  Der Stick ist nicht mehr bootfähig: du müsstest ihn neu\nschreiben, um ihn wieder als Installer zu nutzen.\n\nDie Installation von Home Assistant auf der Platte ist\nnicht betroffen, sie ist fertig."
  S_DONE="Installation abgeschlossen.\n\nHome Assistant OS ist auf %s installiert.\n\n➜ ZIEHE JETZT DEN USB-STICK AB, bevor du bestätigst.\n  (der Installer läuft im Speicher: der Stick wird nicht mehr gebraucht)\n\nWEITER:\n 1. Bestätige unten: der PC startet in Home Assistant.\n 2. Lass das Netzwerkkabel angesteckt.\n 3. Warte 2 bis 5 Minuten (erster Start).\n 4. Von einem anderen Gerät:  http://homeassistant.local"
  S_UNAT_ACTIVE="Unbeaufsichtigte Installation.\n\nKonfigurationsdatei: %s\nSprache: %s\n\nEs wird keine Frage gestellt."
  S_UNAT_NOWIPE="Unbeaufsichtigte Installation abgelehnt.\n\nWIPE=yes fehlt in:\n%s\n\nEs wurde nichts geändert."
  S_UNAT_NODISK="Unbeaufsichtigte Installation abgelehnt.\n\nDISK=%s ist hier keine nutzbare Platte.\n\nEs wurde nichts geändert."
  S_UNAT_MULTI="Unbeaufsichtigte Installation abgelehnt.\n\n%s nutzbare Platten gefunden:\n%s\n\nSetze DISK= auf eine davon in der Konfigurations-\ndatei. Es wurde nichts geändert."
  S_UNAT_NONET="Unbeaufsichtigte Installation fehlgeschlagen.\n\nKein Netzwerk und kein Image auf einem Stick:\nes kann nichts geladen werden.\n\nEs wurde nichts geändert."
  S_UNAT_NOSTAGE="Unbeaufsichtigte Installation abgelehnt.\n\nZu wenig freier RAM für das Image (%s) und kein\nbeschreibbarer Datenträger dafür.\n\nFüge STREAM=yes hinzu, um das Löschen der Platte vor\nder Prüfung des Downloads zu erlauben.\nEs wurde nichts geschrieben."
  S_UNAT_OFF_REBOOT="Installation abgeschlossen.\n\nHome Assistant OS ist auf %s installiert.\n\nZiehe jetzt den USB-Stick ab.\nDer PC startet in 15 Sekunden neu."
  S_UNAT_OFF_HALT="Installation abgeschlossen.\n\nHome Assistant OS ist auf %s installiert.\n\nZiehe jetzt den USB-Stick ab.\nDer PC schaltet sich in 15 Sekunden aus."
  S_UNAT_FAIL="\n\nDas Protokoll erscheint hier und wird gespeichert\nunter %s.\n\nDer PC schaltet sich in 20 Sekunden aus."
;;
da)
  S_STAGE_ASK="Der er ikke ledig hukommelse nok til at holde billedet i RAM (%s).\nDer blev ikke fundet et skrivbart medie med så meget ledig plads.\nSæt en USB-pind eller ekstern disk i, og vælg Prøv igen: billedet hentes dertil og kontrolleres, FØR noget slettes.\n\"Skriv i ét gennemløb\" sletter derimod måldisken først: falder nettet derefter, står du med en tom disk."
  S_STAGE_INFO="Der er ikke hukommelse nok til at lægge billedet i RAM.\nDet hentes til:\n%s\nDer skrives intet på måldisken, før filen er komplet og kontrolleret, og den slettes derfra igen bagefter."
  S_STAGE_RETRY="Prøv igen"
  S_STAGE_STREAM="Skriv i ét gennemløb"
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
  S_SRC_ASK="Hvor skal imaget komme fra?\n\nDownload kræver en internetforbindelse.\nEt image på en USB-pind kræver intet netværk."
  S_SRC_DL="Hent den nyeste version"
  S_SRC_USE="Brug et image på en USB-pind"
  S_IMG_SCAN="Leder efter Home Assistant OS-imager på de\ntilsluttede pinde..."
  S_IMG_NONE="Fandt intet brugbart image.\n\nFilen skal hedde\n  haos_generic-x86-64-<version>.img.xz\n\nFiler fundet, men ubrugelige her:\n%s\n\nSæt en pind i med det rigtige image, eller gå\ntilbage og hent det i stedet."
  S_IMG_PICK="Hvilket image skal skrives til disken?"
  S_IMG_CHECK="Kontrollerer imagets .xz-checksummer..."
  S_IMG_BAD="Dette image kunne ikke verificeres:\n%s\n\n%s\n\nDet er beskadiget, ufuldstændigt eller ikke en\nrigtig .img.xz-fil. Der er intet skrevet til\nnogen disk."
  S_LAN_ASK="Ingen netværksforbindelse.\n\nSæt et Ethernet-(LAN-)kabel i PC'en, og vælg derefter\nPrøv igen.\n\nUden netværk kan imaget ikke hentes.\nDer er ikke skrevet noget til nogen disk endnu."
  S_LAN_RETRY="Prøv igen"
  S_LAN_WIFI="Brug Wi-Fi i stedet"
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
  S_DISK_CONFIRM="Disken %s bliver HELT SLETTET.\n\nNuværende indhold fundet:\n%s\n\nSkriv YES (med stort) for at slette den og installere\nHome Assistant OS.\nAlt andet stopper her, uden at noget slettes."
  S_CONFIRM_T="⚠  SIDSTE BEKRÆFTELSE"
  S_STOP="Stop (anbefales)"
  S_GOON="Fortsæt alligevel"
  S_STOPPED="Stoppet før nogen ændring."
  S_PREP="Forbereder disken %s..."
  S_WRITING="Henter HAOS %s.\nSluk ikke PC'en."
  S_WRITE_HEAD="Skriver imaget til %s.\nSluk ikke PC'en."
  S_DL_CHECK="Tjekker det hentede image..."
  S_DL_RESUME="Fortsætter hentningen: %s af %s ligger allerede på disken."
  S_DL_RETRY="Hentningen stoppede (curl-kode %s).\n\nSidste linjer i loggen:\n%s\n\nFortsæt hvor den stoppede?"
  S_DL_ABORT="Hentningen blev ikke gennemført.\n\nDER BLEV INTET SKREVET: disken er præcis som før,\nog dens indhold er der stadig.\n\nDetalje:\n%s\n\nFuld log: %s"
  S_DL_BAD="Det hentede image er beskadiget (dets .xz-kontrolsummer\npasser ikke) — to gange i træk.\n\nDER BLEV INTET SKREVET: disken er urørt.\nDet peger på netværket eller en cache-proxy, ikke disken.\n\nDetalje:\n%s\n\nFuld log: %s"
  S_DISK_HA="⚠  Denne disk indeholder allerede en Home Assistant-\n   installation (hassos-boot / hassos-data fundet).\n   Sletning ødelægger din konfiguration, dine add-ons\n   og din historik."
  S_FMT_TYPE="Skriv YES for at formatere stikket igen.\nAlt andet lader det være, som det er."
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
  S_FMT_FAIL="Stikket kunne ikke formateres.\n\nIntet blev rørt: det kan stadig bruges som\ninstallationsprogram. Detaljerne står i loggen."
  S_FMT_BROKEN="Formateringen af stikket mislykkedes undervejs.\n\n⚠  Stikket kan ikke længere starte: du skal skrive det igen\nfor at bruge det som installationsprogram.\n\nHome Assistant-installationen på disken er ikke berørt,\nden er færdig."
  S_DONE="Installationen er færdig.\n\nHome Assistant OS er installeret på %s.\n\n➜ TAG USB-STIKKET UD NU, før du bekræfter.\n  (installationsprogrammet kører i hukommelsen: stikket bruges ikke mere)\n\nNÆSTE:\n 1. Bekræft nedenfor: PC'en genstarter i Home Assistant.\n 2. Lad netværkskablet sidde i.\n 3. Vent 2 til 5 minutter (første opstart).\n 4. Fra en anden enhed:  http://homeassistant.local"
  S_UNAT_ACTIVE="Unattended installation.\n\nKonfigurationsfil: %s\nSprog: %s\n\nDer bliver ikke stillet spørgsmål."
  S_UNAT_NOWIPE="Unattended installation afvist.\n\nWIPE=yes mangler i:\n%s\n\nIntet er blevet ændret."
  S_UNAT_NODISK="Unattended installation afvist.\n\nDISK=%s er ikke en brugbar disk her.\n\nIntet er blevet ændret."
  S_UNAT_MULTI="Unattended installation afvist.\n\nFandt %s brugbare diske:\n%s\n\nSæt DISK= til en af dem i konfigurationsfilen.\nIntet er blevet ændret."
  S_UNAT_NONET="Unattended installation mislykkedes.\n\nIntet netværk og ingen image-fil på en stick:\nder kan ikke hentes noget.\n\nIntet er blevet ændret."
  S_UNAT_NOSTAGE="Unattended installation afvist.\n\nFor lidt ledig RAM til image-filen (%s), og intet\nskrivbart medie at lægge den på.\n\nTilføj STREAM=yes for at acceptere at disken slettes,\nfør downloadet er kontrolleret. Intet er skrevet."
  S_UNAT_OFF_REBOOT="Installationen er færdig.\n\nHome Assistant OS er installeret på %s.\n\nTag USB-sticken ud nu.\nPC'en genstarter om 15 sekunder."
  S_UNAT_OFF_HALT="Installationen er færdig.\n\nHome Assistant OS er installeret på %s.\n\nTag USB-sticken ud nu.\nPC'en slukker om 15 sekunder."
  S_UNAT_FAIL="\n\nLoggen vises her på skærmen og gemmes i\n%s.\n\nPC'en slukker om 20 sekunder."
;;
nl)
  S_STAGE_ASK="Niet genoeg vrij geheugen om de image in RAM te houden (%s).\nEr is geen beschrijfbaar medium met zoveel vrije ruimte gevonden.\nSluit een USB-stick of externe schijf aan en kies Opnieuw: de image wordt daarheen gedownload en gecontroleerd, VOORDAT er iets wordt gewist.\n\"In een keer schrijven\" wist juist eerst de doelschijf: valt het netwerk daarna weg, dan blijft er een lege schijf over."
  S_STAGE_INFO="Niet genoeg geheugen om de image in RAM te zetten.\nHij wordt gedownload naar:\n%s\nEr wordt niets naar de doelschijf geschreven voordat het bestand compleet en gecontroleerd is; daarna wordt het daar weer verwijderd."
  S_STAGE_RETRY="Opnieuw"
  S_STAGE_STREAM="In een keer schrijven"
  S_TITLE="Installatie Home Assistant OS"
  S_WARN="⚠  WAARSCHUWING — installatie Home Assistant OS"
  S_RESCUE="\n\nJe kunt het logboek opslaan en de pc daarna uitzetten."
  S_HALT_ASK="Wat nu?\n\nEr verandert niets meer: de installatie is mislukt.\nUitzetten is de normale keuze.\n\nDe terminal is alleen nuttig als je ermee bekend bent."
  S_HALT_OFF="Pc uitzetten"
  S_HALT_SHELL="Terminal openen"
  S_CANCELLED="Installatie geannuleerd."
  S_VFY_ABORT="De schijf komt niet overeen met de image: start er niet van op."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="CONTROLEER DIT (Legacy/CSM-modus gevonden)"
  S_SB_OFF="OK (uitgeschakeld)"
  S_SB_ON="CONTROLEER DIT (ingeschakeld — HAOS start niet)"
  S_SB_UNK="CONTROLEER DIT (status onbekend)"
  S_WELCOME="Welkom.\n\nDit hulpprogramma installeert de nieuwste Home Assistant OS\nop deze pc, zonder opdrachtregel.\n\nCONTROLE VAN DE VEREISTEN:\n  Opstartmodus : %s\n  Secure Boot  : %s\n\n\"CONTROLEER DIT\" betekent dat Home Assistant na de\ninstallatie mogelijk niet start. Los dit op in de BIOS\n(Del/F2 bij het aanzetten). Niets is geblokkeerd: je kunt\ndoorgaan.\n\nBij de schijfstap wordt de HELE gekozen schijf gewist."
  S_NET_ETH="Zoeken naar een bekabelde (Ethernet) verbinding..."
  S_SRC_ASK="Waar moet de image vandaan komen?\n\nDownloaden vereist een internetverbinding.\nEen image op een USB-stick heeft geen netwerk nodig."
  S_SRC_DL="Nieuwste versie downloaden"
  S_SRC_USE="Image op een USB-stick gebruiken"
  S_IMG_SCAN="Zoeken naar Home Assistant OS-images op de\naangesloten sticks..."
  S_IMG_NONE="Geen bruikbare image gevonden.\n\nHet bestand moet heten\n  haos_generic-x86-64-<version>.img.xz\n\nBestanden gevonden, maar hier onbruikbaar:\n%s\n\nSluit een stick met de juiste image aan, of ga\nterug en download hem."
  S_IMG_PICK="Welke image moet naar de schijf worden geschreven?"
  S_IMG_CHECK="Controle van de .xz-controlesommen van de image..."
  S_IMG_BAD="Deze image kon niet worden geverifieerd:\n%s\n\n%s\n\nHij is beschadigd, onvolledig of geen echt\n.img.xz-bestand. Er is niets naar een schijf\ngeschreven."
  S_LAN_ASK="Geen netwerkverbinding.\n\nSluit een Ethernetkabel (LAN) aan op de pc en kies\ndan Opnieuw.\n\nZonder netwerk kan de image niet worden gedownload.\nEr is nog niets naar een schijf geschreven."
  S_LAN_RETRY="Opnieuw"
  S_LAN_WIFI="Liever Wi-Fi"
  S_NET_NOWIFI="Geen bruikbare Wi-Fi-adapter gevonden.\n\n%s\n\nSluit een Ethernetkabel aan, of gebruik handmatige\nconfiguratie in het volgende scherm."
  S_NET_SCAN="Zoeken naar Wi-Fi-netwerken..."
  S_NET_PICK="Kies je Wi-Fi-netwerk:"
  S_NET_RESCAN="[ Opnieuw zoeken ]"
  S_NET_RESCAN_D="geen netwerk? opnieuw proberen"
  S_NET_MANUAL="[ Handmatige configuratie ]"
  S_NET_MANUAL_D="verborgen SSID, WPA enterprise, vast IP (nmtui)"
  S_NET_ETHRETRY="[ Ethernet opnieuw ]"
  S_NET_ETHRETRY_D="kabel inmiddels aangesloten"
  S_NET_QUIT="Installatie afbreken?\n\nEr is geen netwerk geconfigureerd: zonder internet kan\nde installatie niet doorgaan."
  S_NET_PSK="Wachtwoord voor netwerk \"%s\":\n(leesbaar getoond om typefouten te voorkomen)"
  S_NET_CONN="Verbinden met \"%s\"..."
  S_NET_FAIL="Verbinden met \"%s\" is mislukt.\n\n%s\n\nControleer het wachtwoord, of gebruik handmatige\nconfiguratie."
  S_VER_FETCH="Nieuwste versie van Home Assistant OS opzoeken..."
  S_VER_FAIL="De versie van Home Assistant OS kon niet worden bepaald.\n\nBeide bronnen zijn zonder succes geprobeerd:\n  version.home-assistant.io  (stable-kanaal)\n  api.github.com             (nieuwste release)\n\nDe installatie kan niet doorgaan: zonder versie is er\ngeen image om te downloaden.\n\nControleer de internetverbinding en DNS, en start het\ninstallatieprogramma opnieuw."
  S_VER_NOIMG="Geen image gevonden voor versie %s:\n%s"
  S_DISK_NONE="Geen interne schijf gevonden."
  S_DISK_PICK="Op welke schijf moet Home Assistant OS worden geinstalleerd?\nALLE inhoud wordt definitief gewist.\n\nSchijven met [!! USB / EXTERN !!] zijn verwisselbaar: dat is\nwaarschijnlijk een back-upschijf, niet je doel."
  S_DISK_SMALL="Schijf %s is %s GB.\n\nHome Assistant heeft minimaal 32 GB nodig. Schrijven kan\nmislukken of te weinig ruimte overlaten.\n\nEr is nog niets gewist."
  S_DISK_CONFIRM="Schijf %s wordt VOLLEDIG GEWIST.\n\nHuidige inhoud gevonden:\n%s\n\nTyp YES (in hoofdletters) om te wissen en\nHome Assistant OS te installeren.\nElk ander antwoord stopt hier, zonder iets te wissen."
  S_CONFIRM_T="⚠  LAATSTE BEVESTIGING"
  S_STOP="Stoppen (aanbevolen)"
  S_GOON="Toch doorgaan"
  S_STOPPED="Gestopt voordat er iets veranderde."
  S_PREP="Schijf %s voorbereiden..."
  S_WRITING="HAOS %s downloaden.\nZet de pc niet uit."
  S_WRITE_HEAD="Image naar %s schrijven.\nZet de pc niet uit."
  S_DL_CHECK="Gedownloade image controleren..."
  S_DL_RESUME="Download hervatten: %s van %s staat al op schijf."
  S_DL_RETRY="De download stopte (curl-code %s).\n\nLaatste logregels:\n%s\n\nDoorgaan waar hij stopte?"
  S_DL_ABORT="De download is niet voltooid.\n\nER IS NIETS GESCHREVEN: de schijf is precies zoals\nvoorheen, de inhoud staat er nog.\n\nDetail:\n%s\n\nVolledig logboek: %s"
  S_DL_BAD="De gedownloade image is beschadigd (de .xz-controlesommen\nkloppen niet) — twee keer achter elkaar.\n\nER IS NIETS GESCHREVEN: de schijf is onaangeroerd.\nDat wijst op het netwerk of een cacheproxy, niet op\nde schijf.\n\nDetail:\n%s\n\nVolledig logboek: %s"
  S_DISK_HA="⚠  Op deze schijf staat al een Home Assistant-installatie\n   (hassos-boot / hassos-data gevonden). Wissen vernietigt\n   je configuratie, add-ons en geschiedenis."
  S_FMT_TYPE="Typ YES om de stick te formatteren.\nElk ander antwoord laat hem zoals hij is."
  S_FAIL="Installatie mislukt (code %s).\n\nMeest voorkomende oorzaak: de internetverbinding viel weg\ntijdens de download. De schijf is al gewist; opnieuw\nbeginnen is veilig.\n\nDetails:\n%s\n\nVolledig logboek: %s"
  S_VFY_ASK="Controleren of de schijf correct is geschreven?\n\nLeest %s terug van %s.\nDuurt 1 tot 3 minuten, afhankelijk van de schijf.\n\nAanbevolen, zeker bij een oudere schijf."
  S_VFY_RUN="Schijf teruglezen en controleren..."
  S_VFY_OK="Controle geslaagd.\n\nDe inhoud van de schijf komt exact overeen met de image.\n\nSHA256: %s..."
  S_VFY_KO="CONTROLE MISLUKT\n\nDe schijf komt niet overeen met de geschreven image:\n  verwacht: %s...\n  gelezen : %s...\n\nWaarschijnlijke oorzaken: defecte schijf, SATA-kabel,\ngeheugen.\nGEBRUIK DEZE INSTALLATIE NIET: probeer opnieuw en vervang\nde schijf als de fout blijft."
  S_VFY_SKIP="De controlesom van de image is niet berekend: controle\nniet mogelijk.\nDe installatie is vrijwel zeker in orde (de download is\ndoor het gecomprimeerde formaat zelf gevalideerd)."
  S_LOG_ASK="Het installatielogboek naar een USB-stick kopieren?\n\nNa een herstart is het weg. Dit is het bestand om mee te\nsturen als je het probleem meldt."
  S_LOG_OK="Logboek gekopieerd naar %s\n(bestand haos-install-*.log)\n\nJe kunt de stick verwijderen."
  S_LOG_MENU="Waar moet het installatielogboek worden opgeslagen?\n\nEr is automatisch geen beschrijfbaar medium gevonden.\nKies een optie:"
  S_LOG_M_USB="USB-stick aansluiten"
  S_LOG_M_USB_D="wacht 5 s en bevestig"
  S_LOG_M_FMT="Deze stick formatteren"
  S_LOG_M_FMT_D="wist het installatieprogramma"
  S_LOG_M_SHOW="Op het scherm tonen"
  S_LOG_M_SHOW_D="om het te fotograferen"
  S_LOG_M_NONE="Niet opslaan"
  S_LOG_M_NONE_D="het logboek gaat verloren"
  S_LOG_VTOY="De stick wordt herkend, maar is gereserveerd door het\nopstartsysteem en kon niet automatisch worden vrijgegeven.\n\nDit gebeurt bij Ventoy: de installatie-image is een bestand\nop deze stick.\n\n-> KOPPEL de stick LOS, sluit hem OPNIEUW aan, wacht 5\n   seconden en kies hieronder \"USB-stick aansluiten\".\n\nHet installatieprogramma draait in het geheugen: loskoppelen\nis ongevaarlijk."
  S_LOG_RO="Er is een medium gevonden, maar het is alleen-lezen.\n\nDit gebeurt bij Ventoy: het installatiesysteem gebruikt die\npartitie, dus hij kan niet worden gewijzigd.\n\nLoskoppelen en opnieuw aansluiten maakt hem vrij, of kies\neen andere optie."
  S_LOG_DETECT="Media zoeken..."
  S_LOG_RETRY="Nog steeds niets beschrijfbaars.\n\nDe stick is misschien niet gepartitioneerd of het formaat\nwordt niet herkend. Je kunt een andere proberen."
  S_LOG_FULL="Er is een medium gevonden, maar het is vol.\n\nEr is te weinig ruimte voor het logboek. Sluit een andere\nUSB-stick aan, of toon het logboek in de volgende stap op\nhet scherm om het te fotograferen."
  S_LOG_NONE="Logboek niet gekopieerd.\n\nHet is nog leesbaar vanuit de shell:\n  cat %s"
  S_WIFI_PUSH="Wi-Fi-netwerk \"%s\" vooraf ingesteld.\n\nHome Assistant probeert bij de eerste start te verbinden —\nMAAR alleen als je Wi-Fi-kaart door Home Assistant wordt\nondersteund (die lijst is korter dan die van dit\ninstallatieprogramma).\n\nIs Home Assistant na 5 min niet online:\n - sluit een Ethernetkabel aan (aanbevolen), of\n - meld je kaart bij het Home Assistant OS-project.\n\nHoud deze pc binnen Wi-Fi-bereik."
  S_WIFI_PUSH_FAIL="Wi-Fi kon niet in de image worden vooraf ingesteld.\n\nHome Assistant start zonder netwerk: je moet het daarna\nverbinden (Ethernetkabel, of toetsenbord en scherm op de\nHAOS-console)."
  S_WIFI_PUSH_SKIP="Dit Wi-Fi-netwerk kan niet vooraf worden ingesteld.\n\nHet gebruikt certificaten of een modus die Home Assistant\nniet zo kan overnemen. Er is niets geschreven: beter dan een\nnetwerk dat nooit opkomt.\n\nNA DE INSTALLATIE:\n - sluit een Ethernetkabel aan (eenvoudigst), of\n - configureer Wi-Fi vanaf de Home Assistant-console\n   (toetsenbord en scherm op de pc).\n\nDetails staan in het installatielogboek."
  S_DONE_LOG="\n\nDe stick is geformatteerd: het is weer een gewone USB-stick\nen het installatielogboek staat erop."
  S_FMT_ASK="De installer-USB-stick formatteren?\n\n%s\n\nHij wordt weer een gewone FAT32-stick, overal bruikbaar,\nen het installatielogboek wordt erop gekopieerd.\n\n⚠  HET INSTALLATIEPROGRAMMA WORDT GEWIST: om opnieuw te\ninstalleren moet je de stick vanaf een andere computer\nopnieuw schrijven.\n\nDe Home Assistant-installatie die al op de schijf staat,\nblijft ongewijzigd."
  S_FMT_FAIL="De stick kon niet worden geformatteerd.\n\nEr is niets aangeraakt: hij is nog als installer te gebruiken.\nDetails staan in het logboek."
  S_FMT_BROKEN="Het formatteren van de stick is halverwege mislukt.\n\n⚠  De stick is niet meer opstartbaar: je moet hem opnieuw\nschrijven om hem weer als installer te gebruiken.\n\nDe Home Assistant-installatie op de schijf is niet\naangetast, die is compleet."
  S_DONE="Installatie voltooid.\n\nHome Assistant OS staat op %s.\n\n-> VERWIJDER NU DE USB-STICK, voordat je bevestigt.\n   (het installatieprogramma draait in het geheugen)\n\nVOLGENDE:\n 1. Bevestig hieronder: de pc start in Home Assistant.\n 2. Laat de netwerkkabel aangesloten.\n 3. Wacht 2 tot 5 minuten (eerste start).\n 4. Vanaf een ander apparaat:  http://homeassistant.local"
  S_UNAT_ACTIVE="Installatie zonder toezicht.\n\nConfiguratiebestand: %s\nTaal: %s\n\nEr wordt geen vraag gesteld."
  S_UNAT_NOWIPE="Installatie zonder toezicht geweigerd.\n\nWIPE=yes ontbreekt in:\n%s\n\nEr is niets gewijzigd."
  S_UNAT_NODISK="Installatie zonder toezicht geweigerd.\n\nDISK=%s is hier geen bruikbare schijf.\n\nEr is niets gewijzigd."
  S_UNAT_MULTI="Installatie zonder toezicht geweigerd.\n\n%s bruikbare schijven gevonden:\n%s\n\nZet DISK= op een daarvan in het configuratie-\nbestand. Er is niets gewijzigd."
  S_UNAT_NONET="Installatie zonder toezicht mislukt.\n\nGeen netwerk en geen image op een stick:\ner kan niets worden gedownload.\n\nEr is niets gewijzigd."
  S_UNAT_NOSTAGE="Installatie zonder toezicht geweigerd.\n\nTe weinig vrij RAM voor het image (%s) en geen\nbeschrijfbaar medium om het op te zetten.\n\nVoeg STREAM=yes toe om het wissen van de schijf\nvóór de downloadcontrole toe te staan.\nEr is niets geschreven."
  S_UNAT_OFF_REBOOT="Installatie voltooid.\n\nHome Assistant OS staat op %s.\n\nHaal de USB-stick er nu uit.\nDe PC start over 15 seconden opnieuw."
  S_UNAT_OFF_HALT="Installatie voltooid.\n\nHome Assistant OS staat op %s.\n\nHaal de USB-stick er nu uit.\nDe PC schakelt over 15 seconden uit."
  S_UNAT_FAIL="\n\nHet log verschijnt hier en wordt bewaard in\n%s.\n\nDe PC schakelt over 20 seconden uit."
;;
es)
  S_STAGE_ASK="No hay memoria libre suficiente para mantener la imagen en RAM (%s).\nNo se encontro ningun medio escribible con ese espacio libre.\nConecta un pendrive o un disco externo y elige Reintentar: la imagen se descarga alli y se comprueba ANTES de borrar nada.\n\"Escribir en una pasada\" borra primero el disco destino: si la red cae despues, queda un disco vacio."
  S_STAGE_INFO="No hay memoria suficiente para dejar la imagen en RAM.\nSe descarga en:\n%s\nNo se escribe nada en el disco destino hasta que el archivo este completo y comprobado, y despues se borra de alli."
  S_STAGE_RETRY="Reintentar"
  S_STAGE_STREAM="Escribir en una pasada"
  S_TITLE="Instalacion de Home Assistant OS"
  S_WARN="⚠  AVISO — Instalacion de Home Assistant OS"
  S_RESCUE="\n\nPodras guardar el registro y apagar el PC."
  S_HALT_ASK="Y ahora?\n\nNo cambiara nada mas: la instalacion ha fallado.\nApagar es la opcion normal.\n\nLa terminal solo sirve si sabes moverte por ella."
  S_HALT_OFF="Apagar el PC"
  S_HALT_SHELL="Abrir una terminal"
  S_CANCELLED="Instalacion cancelada."
  S_VFY_ABORT="El disco no coincide con la imagen: no arranques desde el."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="COMPRUEBA ESTO (modo Legacy/CSM detectado)"
  S_SB_OFF="OK (desactivado)"
  S_SB_ON="COMPRUEBA ESTO (activado — HAOS no arrancara)"
  S_SB_UNK="COMPRUEBA ESTO (estado desconocido)"
  S_WELCOME="Bienvenido.\n\nEsta herramienta instala la ultima version de Home Assistant OS\nen este PC, sin usar la linea de comandos.\n\nCOMPROBACION DE REQUISITOS:\n  Modo de arranque : %s\n  Secure Boot      : %s\n\n\"COMPRUEBA ESTO\" significa que Home Assistant podria no\narrancar tras la instalacion. Se corrige en la BIOS\n(Supr/F2 al encender). Nada esta bloqueado: puedes seguir.\n\nEn el paso del disco se borrara TODO el disco elegido."
  S_NET_ETH="Buscando una conexion por cable (Ethernet)..."
  S_SRC_ASK="¿De dónde debe venir la imagen?\n\nDescargar requiere conexión a Internet. Una\nimagen en un lápiz USB no necesita red."
  S_SRC_DL="Descargar la última versión"
  S_SRC_USE="Usar una imagen de un lápiz USB"
  S_IMG_SCAN="Buscando imágenes de Home Assistant OS en los\nlápices conectados..."
  S_IMG_NONE="No se encontró ninguna imagen utilizable.\n\nEl archivo debe llamarse\n  haos_generic-x86-64-<version>.img.xz\n\nArchivos encontrados pero inutilizables aquí:\n%s\n\nConecta un lápiz con la imagen correcta, o\nvuelve atrás y descárgala."
  S_IMG_PICK="¿Qué imagen se debe escribir en el disco?"
  S_IMG_CHECK="Comprobando las sumas .xz de la imagen..."
  S_IMG_BAD="No se pudo verificar esta imagen:\n%s\n\n%s\n\nEstá dañada, incompleta, o no es un archivo\n.img.xz de verdad. No se ha escrito nada en\nningún disco."
  S_LAN_ASK="Sin conexion de red.\n\nConecta un cable Ethernet (LAN) al PC y elige\nReintentar.\n\nSin red no se puede descargar la imagen.\nTodavia no se ha escrito nada en ningun disco."
  S_LAN_RETRY="Reintentar"
  S_LAN_WIFI="Usar Wi-Fi"
  S_NET_NOWIFI="No se ha detectado ningun adaptador Wi-Fi utilizable.\n\n%s\n\nConecta un cable Ethernet o usa la configuracion manual\nen la pantalla siguiente."
  S_NET_SCAN="Buscando redes Wi-Fi..."
  S_NET_PICK="Elige tu red Wi-Fi:"
  S_NET_RESCAN="[ Buscar otra vez ]"
  S_NET_RESCAN_D="no aparece? reintentar"
  S_NET_MANUAL="[ Configuracion manual ]"
  S_NET_MANUAL_D="SSID oculto, WPA enterprise, IP fija (nmtui)"
  S_NET_ETHRETRY="[ Reintentar Ethernet ]"
  S_NET_ETHRETRY_D="cable conectado mientras tanto"
  S_NET_QUIT="Salir del instalador?\n\nNo hay red configurada: la instalacion no puede\ncontinuar sin acceso a Internet."
  S_NET_PSK="Contrasena de la red \"%s\":\n(se muestra en claro para evitar errores)"
  S_NET_CONN="Conectando a \"%s\"..."
  S_NET_FAIL="No se pudo conectar a \"%s\".\n\n%s\n\nComprueba la contrasena o usa la configuracion manual."
  S_VER_FETCH="Buscando la ultima version de Home Assistant OS..."
  S_VER_FAIL="No se pudo determinar la version de Home Assistant OS.\n\nSe probaron las dos fuentes sin exito:\n  version.home-assistant.io  (canal stable)\n  api.github.com             (ultima version)\n\nLa instalacion no puede continuar: sin version no hay\nimagen que descargar.\n\nComprueba el acceso a Internet y el DNS, y vuelve a\niniciar el instalador."
  S_VER_NOIMG="No se encontro imagen para la version %s:\n%s"
  S_DISK_NONE="No se ha detectado ningun disco interno."
  S_DISK_PICK="En que disco se instalara Home Assistant OS?\nTODO su contenido se borrara de forma permanente.\n\nLos discos marcados [!! USB / EXTERNO !!] son extraibles:\nprobablemente sea un disco de copias, no tu destino."
  S_DISK_SMALL="El disco %s tiene %s GB.\n\nHome Assistant necesita 32 GB como minimo. La escritura\npuede fallar o dejar muy poco espacio util.\n\nTodavia no se ha borrado nada."
  S_DISK_CONFIRM="El disco %s se borrara POR COMPLETO.\n\nContenido actual detectado:\n%s\n\nEscribe YES (en mayusculas) para borrarlo e instalar\nHome Assistant OS.\nCualquier otra respuesta se detiene aqui, sin borrar nada."
  S_CONFIRM_T="⚠  CONFIRMACION FINAL"
  S_STOP="Detener (recomendado)"
  S_GOON="Continuar igualmente"
  S_STOPPED="Detenido antes de cambiar nada."
  S_PREP="Preparando el disco %s..."
  S_WRITING="Descargando HAOS %s.\nNo apagues el PC."
  S_WRITE_HEAD="Escribiendo la imagen en %s.\nNo apagues el PC."
  S_DL_CHECK="Comprobando la imagen descargada..."
  S_DL_RESUME="Reanudando la descarga: %s de %s ya en el disco."
  S_DL_RETRY="La descarga se detuvo (codigo curl %s).\n\nUltimas lineas del registro:\n%s\n\nContinuar donde se quedo?"
  S_DL_ABORT="La descarga no se completo.\n\nNO SE HA ESCRITO NADA: el disco esta exactamente como\nestaba y su contenido sigue ahi.\n\nDetalle:\n%s\n\nRegistro completo: %s"
  S_DL_BAD="La imagen descargada esta danada (sus sumas de\ncontrol .xz no coinciden) — dos veces seguidas.\n\nNO SE HA ESCRITO NADA: el disco esta intacto.\nEso apunta a la red o a un proxy con cache, no al disco.\n\nDetalle:\n%s\n\nRegistro completo: %s"
  S_DISK_HA="⚠  Este disco ya contiene una instalacion de Home Assistant\n   (se han encontrado hassos-boot / hassos-data). Borrarlo\n   destruye tu configuracion, tus complementos y tu historial."
  S_FMT_TYPE="Escribe YES para formatear el lapiz.\nCualquier otra respuesta lo deja tal como esta."
  S_FAIL="La instalacion ha fallado (codigo %s).\n\nCausa mas habitual: la conexion a Internet se corto durante\nla descarga. El disco ya esta borrado; empezar de nuevo\nes seguro.\n\nDetalles:\n%s\n\nRegistro completo: %s"
  S_VFY_ASK="Comprobar que el disco se ha escrito correctamente?\n\nRelee %s desde %s.\nTarda de 1 a 3 minutos segun el disco.\n\nRecomendado, sobre todo en un disco antiguo."
  S_VFY_RUN="Releyendo y comprobando el disco..."
  S_VFY_OK="Comprobacion superada.\n\nEl contenido del disco coincide exactamente con la imagen.\n\nSHA256: %s..."
  S_VFY_KO="COMPROBACION FALLIDA\n\nEl disco no coincide con la imagen escrita:\n  esperado: %s...\n  leido   : %s...\n\nCausas probables: disco defectuoso, cable SATA, memoria.\nNO uses esta instalacion: intentalo de nuevo y, si el error\npersiste, cambia el disco."
  S_VFY_SKIP="No se calculo la suma de control de la imagen: no se puede\ncomprobar.\nLa instalacion es casi seguro correcta (la descarga la\nvalida el propio formato comprimido)."
  S_LOG_ASK="Copiar el registro de instalacion a un lapiz USB?\n\nSi no, se pierde al reiniciar. Es el archivo que hay que\nadjuntar al informar del problema."
  S_LOG_OK="Registro copiado en %s\n(archivo haos-install-*.log)\n\nYa puedes quitar el lapiz."
  S_LOG_MENU="Donde se guarda el registro de instalacion?\n\nNo se ha encontrado automaticamente ningun medio\nescribible. Elige una opcion:"
  S_LOG_M_USB="Conectar un lapiz USB"
  S_LOG_M_USB_D="espera 5 s y confirma"
  S_LOG_M_FMT="Formatear este lapiz"
  S_LOG_M_FMT_D="borra el instalador"
  S_LOG_M_SHOW="Mostrar en pantalla"
  S_LOG_M_SHOW_D="para fotografiarlo"
  S_LOG_M_NONE="No guardar"
  S_LOG_M_NONE_D="el registro se perdera"
  S_LOG_VTOY="El lapiz se reconoce, pero el sistema de arranque lo\ntiene reservado y no se pudo liberar automaticamente.\n\nOcurre con Ventoy: la imagen de instalacion es un archivo\nen este lapiz.\n\n-> DESCONECTA y vuelve a CONECTAR el lapiz, espera 5\n   segundos y elige \"Conectar un lapiz USB\" abajo.\n\nEl instalador se ejecuta en memoria: desconectarlo es\ninofensivo."
  S_LOG_RO="Se ha encontrado un medio, pero es de solo lectura.\n\nOcurre con Ventoy: el sistema de instalacion esta usando esa\nparticion, asi que no se puede modificar.\n\nDesconectar y volver a conectar el lapiz lo libera, o elige\notra opcion."
  S_LOG_DETECT="Detectando medios..."
  S_LOG_RETRY="Sigue sin haber nada escribible.\n\nEl lapiz puede no tener particiones o su formato no se\nreconoce. Puedes probar con otro."
  S_LOG_FULL="Se ha encontrado un medio, pero esta lleno.\n\nNo hay espacio para el registro. Conecta otro lapiz USB,\no muestra el registro en pantalla en el paso siguiente para\nfotografiarlo."
  S_LOG_NONE="Registro no copiado.\n\nSigue siendo legible desde la shell:\n  cat %s"
  S_WIFI_PUSH="Red Wi-Fi \"%s\" preconfigurada.\n\nHome Assistant intentara conectarse en el primer arranque,\nPERO solo si tu tarjeta Wi-Fi esta entre las que admite\n(su lista es mas corta que la de este instalador).\n\nSi Home Assistant no esta en linea a los 5 min:\n - conecta un cable Ethernet (recomendado), o\n - informa de tu tarjeta al proyecto Home Assistant OS.\n\nManten este PC dentro del alcance del Wi-Fi."
  S_WIFI_PUSH_FAIL="No se pudo preconfigurar el Wi-Fi en la imagen.\n\nHome Assistant arrancara sin red: tendras que conectarlo\ndespues (cable Ethernet, o teclado y pantalla en la consola\nde HAOS)."
  S_WIFI_PUSH_SKIP="Esta red Wi-Fi no se puede preconfigurar.\n\nDepende de certificados o de un modo que Home Assistant no\npuede asumir tal cual. No se escribio nada: mejor eso que\nuna red que nunca aparece.\n\nQUE HACER TRAS LA INSTALACION:\n - conecta un cable Ethernet (lo mas simple), o\n - configura el Wi-Fi desde la consola de Home Assistant\n   (teclado y pantalla en el PC).\n\nLos detalles estan en el registro de instalacion."
  S_DONE_LOG="\n\nEl lapiz se ha formateado: vuelve a ser un USB normal y el\nregistro de instalacion se ha copiado en el."
  S_FMT_ASK="Formatear el lapiz USB del instalador?\n\n%s\n\nVolveria a ser un lapiz FAT32 normal, utilizable en\ncualquier sitio, y el registro se copiaria en el.\n\n⚠  SE BORRARA EL INSTALADOR: para reinstalar tendrias que\ngrabar el lapiz de nuevo desde otro ordenador.\n\nLa instalacion de Home Assistant ya escrita en el disco no\nse ve afectada."
  S_FMT_FAIL="No se pudo formatear el lapiz.\n\nNo se ha tocado nada: sigue sirviendo como instalador.\nLos detalles estan en el registro."
  S_FMT_BROKEN="El formateo del lapiz fallo a medias.\n\n⚠  El lapiz ya no arranca: tendras que grabarlo de nuevo\npara reutilizarlo como instalador.\n\nLa instalacion de Home Assistant en el disco no se ve\nafectada, esta completa."
  S_DONE="Instalacion completada.\n\nHome Assistant OS esta instalado en %s.\n\n-> QUITA EL LAPIZ USB AHORA, antes de confirmar.\n   (el instalador se ejecuta en memoria: ya no se usa)\n\nSIGUIENTE:\n 1. Confirma abajo: el PC arranca en Home Assistant.\n 2. Deja el cable de red conectado.\n 3. Espera de 2 a 5 minutos (primer arranque).\n 4. Desde otro dispositivo:  http://homeassistant.local"
  S_UNAT_ACTIVE="Instalación desatendida.\n\nArchivo de configuración: %s\nIdioma: %s\n\nNo se hará ninguna pregunta."
  S_UNAT_NOWIPE="Instalación desatendida rechazada.\n\nFalta WIPE=yes en:\n%s\n\nNo se ha cambiado nada."
  S_UNAT_NODISK="Instalación desatendida rechazada.\n\nDISK=%s no es un disco utilizable aquí.\n\nNo se ha cambiado nada."
  S_UNAT_MULTI="Instalación desatendida rechazada.\n\nSe encontraron %s discos utilizables:\n%s\n\nPon DISK= en uno de ellos en el archivo de\nconfiguración. No se ha cambiado nada."
  S_UNAT_NONET="La instalación desatendida falló.\n\nSin red y sin imagen en un lápiz:\nno se puede descargar nada.\n\nNo se ha cambiado nada."
  S_UNAT_NOSTAGE="Instalación desatendida rechazada.\n\nPoca RAM libre para la imagen (%s) y ningún\nmedio escribible donde guardarla.\n\nAñade STREAM=yes para aceptar borrar el disco\nantes de comprobar la descarga.\nNo se ha escrito nada."
  S_UNAT_OFF_REBOOT="Instalación completada.\n\nHome Assistant OS está instalado en %s.\n\nRetira el lápiz USB ahora.\nEl PC se reinicia en 15 segundos."
  S_UNAT_OFF_HALT="Instalación completada.\n\nHome Assistant OS está instalado en %s.\n\nRetira el lápiz USB ahora.\nEl PC se apaga en 15 segundos."
  S_UNAT_FAIL="\n\nEl registro aparece aquí y se guarda en\n%s.\n\nEl PC se apaga en 20 segundos."
;;
it)
  S_STAGE_ASK="Memoria libera insufficiente per tenere l'immagine in RAM (%s).\nNessun supporto scrivibile con altrettanto spazio libero e stato trovato.\nCollega una chiavetta o un disco esterno e scegli Riprova: l'immagine viene scaricata li e controllata PRIMA di cancellare qualsiasi cosa.\n\"Scrivere in un solo passaggio\" cancella invece prima il disco di destinazione: se la rete cade dopo, resta un disco vuoto."
  S_STAGE_INFO="Memoria insufficiente per mettere l'immagine in RAM.\nViene scaricata in:\n%s\nNon viene scritto nulla sul disco di destinazione finche il file non e completo e controllato, e poi viene cancellato da li."
  S_STAGE_RETRY="Riprova"
  S_STAGE_STREAM="Scrivere in un solo passaggio"
  S_TITLE="Installazione di Home Assistant OS"
  S_WARN="⚠  AVVISO — installazione di Home Assistant OS"
  S_RESCUE="\n\nPotrai salvare il registro, poi spegnere il PC."
  S_HALT_ASK="E adesso?\n\nNon cambiera piu nulla: l'installazione e fallita.\nSpegnere e la scelta normale.\n\nIl terminale serve solo se sai muoverti al suo interno."
  S_HALT_OFF="Spegnere il PC"
  S_HALT_SHELL="Aprire un terminale"
  S_CANCELLED="Installazione annullata."
  S_VFY_ABORT="Il disco non corrisponde all'immagine: non avviarlo."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="CONTROLLA QUESTO (modalita Legacy/CSM rilevata)"
  S_SB_OFF="OK (disattivato)"
  S_SB_ON="CONTROLLA QUESTO (attivo — HAOS non si avvia)"
  S_SB_UNK="CONTROLLA QUESTO (stato sconosciuto)"
  S_WELCOME="Benvenuto.\n\nQuesto strumento installa l'ultima versione di Home Assistant OS\nsu questo PC, senza riga di comando.\n\nVERIFICA DEI REQUISITI:\n  Modalita di avvio : %s\n  Secure Boot       : %s\n\n\"CONTROLLA QUESTO\" significa che Home Assistant potrebbe non\navviarsi dopo l'installazione. Si sistema nel BIOS\n(Canc/F2 all'accensione). Nulla e bloccato: puoi proseguire.\n\nAl passaggio del disco verra cancellato TUTTO il disco scelto."
  S_NET_ETH="Ricerca di una connessione via cavo (Ethernet)..."
  S_SRC_ASK="Da dove deve arrivare l'immagine?\n\nIl download richiede una connessione Internet.\nUn'immagine su chiavetta non richiede rete."
  S_SRC_DL="Scaricare l'ultima versione"
  S_SRC_USE="Usare un'immagine su chiavetta USB"
  S_IMG_SCAN="Ricerca di immagini Home Assistant OS sulle\nchiavette collegate..."
  S_IMG_NONE="Nessuna immagine utilizzabile trovata.\n\nIl file deve chiamarsi\n  haos_generic-x86-64-<version>.img.xz\n\nFile trovati ma inutilizzabili qui:\n%s\n\nInserisci una chiavetta con l'immagine giusta,\no torna indietro e scaricala."
  S_IMG_PICK="Quale immagine scrivere sul disco?"
  S_IMG_CHECK="Controllo dei checksum .xz dell'immagine..."
  S_IMG_BAD="Impossibile verificare questa immagine:\n%s\n\n%s\n\nE danneggiata, incompleta, o non e davvero un\nfile .img.xz. Non e stato scritto nulla su\nnessun disco."
  S_LAN_ASK="Nessuna connessione di rete.\n\nCollega un cavo Ethernet (LAN) al PC, poi scegli\nRiprova.\n\nSenza rete l'immagine non puo essere scaricata.\nNon e ancora stato scritto nulla su alcun disco."
  S_LAN_RETRY="Riprova"
  S_LAN_WIFI="Usa il Wi-Fi"
  S_NET_NOWIFI="Nessun adattatore Wi-Fi utilizzabile rilevato.\n\n%s\n\nCollega un cavo Ethernet, oppure usa la configurazione\nmanuale nella schermata successiva."
  S_NET_SCAN="Ricerca delle reti Wi-Fi..."
  S_NET_PICK="Scegli la tua rete Wi-Fi:"
  S_NET_RESCAN="[ Cerca di nuovo ]"
  S_NET_RESCAN_D="rete non trovata? riprova"
  S_NET_MANUAL="[ Configurazione manuale ]"
  S_NET_MANUAL_D="SSID nascosto, WPA enterprise, IP statico (nmtui)"
  S_NET_ETHRETRY="[ Riprova Ethernet ]"
  S_NET_ETHRETRY_D="cavo collegato nel frattempo"
  S_NET_QUIT="Uscire dall'installer?\n\nNessuna rete configurata: l'installazione non puo\nproseguire senza accesso a Internet."
  S_NET_PSK="Password della rete \"%s\":\n(visibile per evitare errori di battitura)"
  S_NET_CONN="Connessione a \"%s\"..."
  S_NET_FAIL="Connessione a \"%s\" non riuscita.\n\n%s\n\nControlla la password, oppure usa la configurazione\nmanuale."
  S_VER_FETCH="Ricerca dell'ultima versione di Home Assistant OS..."
  S_VER_FAIL="Impossibile determinare la versione di Home Assistant OS.\n\nEntrambe le fonti sono state provate senza successo:\n  version.home-assistant.io  (canale stable)\n  api.github.com             (ultima release)\n\nL'installazione non puo proseguire: senza versione non c'e\nimmagine da scaricare.\n\nControlla l'accesso a Internet e il DNS, poi avvia di nuovo\nl'installer."
  S_VER_NOIMG="Nessuna immagine trovata per la versione %s:\n%s"
  S_DISK_NONE="Nessun disco interno rilevato."
  S_DISK_PICK="Su quale disco installare Home Assistant OS?\nTUTTO il suo contenuto sara cancellato definitivamente.\n\nI dischi marcati [!! USB / ESTERNO !!] sono rimovibili:\nprobabilmente e un disco di backup, non il tuo obiettivo."
  S_DISK_SMALL="Il disco %s e da %s GB.\n\nHome Assistant richiede almeno 32 GB. La scrittura puo\nfallire o lasciare troppo poco spazio.\n\nNon e ancora stato cancellato nulla."
  S_DISK_CONFIRM="Il disco %s sara CANCELLATO COMPLETAMENTE.\n\nContenuto attuale rilevato:\n%s\n\nScrivi YES (in maiuscolo) per cancellarlo e installare\nHome Assistant OS.\nQualsiasi altra risposta si ferma qui, senza cancellare nulla."
  S_CONFIRM_T="⚠  CONFERMA FINALE"
  S_STOP="Fermarsi (consigliato)"
  S_GOON="Proseguire comunque"
  S_STOPPED="Fermato prima di qualsiasi modifica."
  S_PREP="Preparazione del disco %s..."
  S_WRITING="Download di HAOS %s.\nNon spegnere il PC."
  S_WRITE_HEAD="Scrittura dell'immagine su %s.\nNon spegnere il PC."
  S_DL_CHECK="Verifica dell'immagine scaricata..."
  S_DL_RESUME="Ripresa del download: %s di %s gia sul disco."
  S_DL_RETRY="Il download si e fermato (codice curl %s).\n\nUltime righe del registro:\n%s\n\nRiprendere da dove si era fermato?"
  S_DL_ABORT="Il download non e stato completato.\n\nNON E STATO SCRITTO NULLA: il disco e esattamente com'era\ne il suo contenuto e ancora li.\n\nDettaglio:\n%s\n\nRegistro completo: %s"
  S_DL_BAD="L'immagine scaricata e danneggiata (i checksum .xz non\ncorrispondono) — due volte di seguito.\n\nNON E STATO SCRITTO NULLA: il disco e intatto.\nQuesto indica la rete o un proxy con cache, non il disco.\n\nDettaglio:\n%s\n\nRegistro completo: %s"
  S_DISK_HA="⚠  Questo disco contiene gia un'installazione di Home\n   Assistant (trovati hassos-boot / hassos-data). Cancellarla\n   distrugge configurazione, componenti aggiuntivi e storico."
  S_FMT_TYPE="Scrivi YES per formattare la chiavetta.\nQualsiasi altra risposta la lascia com'e."
  S_FAIL="Installazione non riuscita (codice %s).\n\nCausa piu comune: la connessione a Internet e caduta durante\nil download. Il disco e gia stato cancellato; ricominciare\nda capo e sicuro.\n\nDettagli:\n%s\n\nRegistro completo: %s"
  S_VFY_ASK="Verificare che il disco sia stato scritto correttamente?\n\nRilegge %s da %s.\nRichiede da 1 a 3 minuti secondo il disco.\n\nConsigliato, soprattutto su un disco vecchio."
  S_VFY_RUN="Rilettura e verifica del disco..."
  S_VFY_OK="Verifica superata.\n\nIl contenuto del disco corrisponde esattamente all'immagine.\n\nSHA256: %s..."
  S_VFY_KO="VERIFICA NON RIUSCITA\n\nIl disco non corrisponde all'immagine scritta:\n  atteso: %s...\n  letto : %s...\n\nCause probabili: disco guasto, cavo SATA, memoria.\nNON usare questa installazione: riprova e, se l'errore\npersiste, sostituisci il disco."
  S_VFY_SKIP="Il checksum dell'immagine non e stato calcolato: verifica\nimpossibile.\nL'installazione e quasi certamente a posto (il download e\nvalidato dal formato compresso stesso)."
  S_LOG_ASK="Copiare il registro dell'installazione su una chiavetta USB?\n\nAltrimenti si perde al riavvio. E il file da allegare quando\nsegnali il problema."
  S_LOG_OK="Registro copiato su %s\n(file haos-install-*.log)\n\nPuoi rimuovere la chiavetta."
  S_LOG_MENU="Dove salvare il registro dell'installazione?\n\nNessun supporto scrivibile e stato trovato\nautomaticamente. Scegli un'opzione:"
  S_LOG_M_USB="Collega una chiavetta USB"
  S_LOG_M_USB_D="attendi 5 s, poi conferma"
  S_LOG_M_FMT="Formatta questa chiavetta"
  S_LOG_M_FMT_D="cancella l'installer"
  S_LOG_M_SHOW="Mostra a schermo"
  S_LOG_M_SHOW_D="per fotografarlo"
  S_LOG_M_NONE="Non salvare"
  S_LOG_M_NONE_D="il registro andra perso"
  S_LOG_VTOY="La chiavetta e riconosciuta, ma e riservata dal sistema\ndi avvio e non e stato possibile liberarla\nautomaticamente.\n\nSuccede con Ventoy: l'immagine di installazione e un file\nsu questa chiavetta.\n\n-> SCOLLEGA e RICOLLEGA la chiavetta, attendi 5 secondi e\n   scegli \"Collega una chiavetta USB\" qui sotto.\n\nL'installer gira in memoria: scollegarla non e un problema."
  S_LOG_RO="E stato trovato un supporto, ma e in sola lettura.\n\nSuccede con Ventoy: il sistema di installazione sta usando\nquella partizione, quindi non puo essere modificata.\n\nScollegare e ricollegare la chiavetta la libera, oppure\nscegli un'altra opzione."
  S_LOG_DETECT="Rilevamento dei supporti..."
  S_LOG_RETRY="Ancora nulla di scrivibile.\n\nLa chiavetta potrebbe non essere partizionata o il formato\nnon essere riconosciuto. Puoi provarne un'altra."
  S_LOG_FULL="E stato trovato un supporto, ma e pieno.\n\nNon c'e spazio per il registro. Collega un'altra chiavetta\nUSB, oppure mostra il registro a schermo al passaggio\nsuccessivo per fotografarlo."
  S_LOG_NONE="Registro non copiato.\n\nE ancora leggibile dalla shell:\n  cat %s"
  S_WIFI_PUSH="Rete Wi-Fi \"%s\" preconfigurata.\n\nHome Assistant provera a connettersi al primo avvio, MA solo\nse la tua scheda Wi-Fi e tra quelle supportate (il suo\nelenco e piu ristretto di quello di questo installer).\n\nSe Home Assistant non e online dopo 5 min:\n - collega un cavo Ethernet (consigliato), oppure\n - segnala la tua scheda al progetto Home Assistant OS.\n\nTieni questo PC nel raggio del Wi-Fi."
  S_WIFI_PUSH_FAIL="Non e stato possibile preconfigurare il Wi-Fi\nnell'immagine.\n\nHome Assistant si avviera senza rete: dovrai collegarlo dopo\n(cavo Ethernet, oppure tastiera e schermo sulla console di\nHAOS)."
  S_WIFI_PUSH_SKIP="Questa rete Wi-Fi non puo essere preconfigurata.\n\nSi basa su certificati o su una modalita che Home Assistant\nnon puo riprendere cosi com'e. Non e stato scritto nulla:\nmeglio cosi che una rete che non parte mai.\n\nDA FARE DOPO L'INSTALLAZIONE:\n - collega un cavo Ethernet (il piu semplice), oppure\n - configura il Wi-Fi dalla console di Home Assistant\n   (tastiera e schermo sul PC).\n\nI dettagli sono nel registro dell'installazione."
  S_DONE_LOG="\n\nLa chiavetta e stata formattata: e di nuovo una normale\nchiavetta USB e il registro vi e stato copiato."
  S_FMT_ASK="Formattare la chiavetta USB dell'installer?\n\n%s\n\nTornerebbe una normale chiavetta FAT32, utilizzabile\novunque, e il registro vi sarebbe copiato.\n\n⚠  L'INSTALLER SARA CANCELLATO: per reinstallare dovresti\nriscrivere la chiavetta da un altro computer.\n\nL'installazione di Home Assistant gia scritta sul disco non\ne interessata."
  S_FMT_FAIL="Non e stato possibile formattare la chiavetta.\n\nNon e stato toccato nulla: e ancora utilizzabile come\ninstaller. I dettagli sono nel registro."
  S_FMT_BROKEN="La formattazione della chiavetta e fallita a meta.\n\n⚠  La chiavetta non e piu avviabile: dovrai riscriverla per\nriutilizzarla come installer.\n\nL'installazione di Home Assistant sul disco non e\ninteressata, e completa."
  S_DONE="Installazione completata.\n\nHome Assistant OS e installato su %s.\n\n-> RIMUOVI ORA LA CHIAVETTA USB, prima di confermare.\n   (l'installer gira in memoria: non serve piu)\n\nPROSSIMI PASSI:\n 1. Conferma qui sotto: il PC si riavvia in Home Assistant.\n 2. Lascia collegato il cavo di rete.\n 3. Attendi da 2 a 5 minuti (primo avvio).\n 4. Da un altro dispositivo:  http://homeassistant.local"
  S_UNAT_ACTIVE="Installazione senza assistenza.\n\nFile di configurazione: %s\nLingua: %s\n\nNessuna domanda verrà posta."
  S_UNAT_NOWIPE="Installazione senza assistenza rifiutata.\n\nManca WIPE=yes in:\n%s\n\nNon è stato modificato nulla."
  S_UNAT_NODISK="Installazione senza assistenza rifiutata.\n\nDISK=%s non è un disco utilizzabile qui.\n\nNon è stato modificato nulla."
  S_UNAT_MULTI="Installazione senza assistenza rifiutata.\n\nTrovati %s dischi utilizzabili:\n%s\n\nImposta DISK= su uno di essi nel file di\nconfigurazione. Non è stato modificato nulla."
  S_UNAT_NONET="Installazione senza assistenza fallita.\n\nNessuna rete e nessuna immagine su una chiavetta:\nnon si può scaricare nulla.\n\nNon è stato modificato nulla."
  S_UNAT_NOSTAGE="Installazione senza assistenza rifiutata.\n\nRAM libera insufficiente per l'immagine (%s) e\nnessun supporto scrivibile per tenerla.\n\nAggiungi STREAM=yes per accettare di cancellare\nil disco prima del controllo del download.\nNon è stato scritto nulla."
  S_UNAT_OFF_REBOOT="Installazione completata.\n\nHome Assistant OS è installato su %s.\n\nRimuovi ora la chiavetta USB.\nIl PC si riavvia tra 15 secondi."
  S_UNAT_OFF_HALT="Installazione completata.\n\nHome Assistant OS è installato su %s.\n\nRimuovi ora la chiavetta USB.\nIl PC si spegne tra 15 secondi."
  S_UNAT_FAIL="\n\nIl registro appare qui e viene salvato in\n%s.\n\nIl PC si spegne tra 20 secondi."
;;
pl)
  S_STAGE_ASK="Za malo wolnej pamieci, aby trzymac obraz w RAM (%s).\nNie znaleziono zapisywalnego nosnika z tyle wolnego miejsca.\nPodlacz pendrive lub dysk zewnetrzny i wybierz Ponow: obraz zostanie tam pobrany i sprawdzony, ZANIM cokolwiek zostanie usuniete.\n\"Zapis w jednym przebiegu\" najpierw czysci dysk docelowy: jesli siec padnie pozniej, zostanie pusty dysk."
  S_STAGE_INFO="Za malo pamieci, aby umiescic obraz w RAM.\nJest pobierany do:\n%s\nNa dysk docelowy nic nie jest zapisywane, dopoki plik nie bedzie kompletny i sprawdzony, a potem jest stamtad usuwany."
  S_STAGE_RETRY="Ponow"
  S_STAGE_STREAM="Zapis w jednym przebiegu"
  S_TITLE="Instalacja Home Assistant OS"
  S_WARN="⚠  OSTRZEZENIE — instalacja Home Assistant OS"
  S_RESCUE="\n\nBedziesz mogl zapisac dziennik, a potem wylaczyc komputer."
  S_HALT_ASK="Co teraz?\n\nNic wiecej sie nie zmieni: instalacja zakonczyla sie\nniepowodzeniem. Wylaczenie to normalny wybor.\n\nTerminal przyda sie tylko, jesli potrafisz sie w nim\nporuszac."
  S_HALT_OFF="Wylacz komputer"
  S_HALT_SHELL="Otworz terminal"
  S_CANCELLED="Instalacja anulowana."
  S_VFY_ABORT="Dysk nie zgadza sie z obrazem: nie uruchamiaj z niego systemu."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="SPRAWDZ TO (wykryto tryb Legacy/CSM)"
  S_SB_OFF="OK (wylaczony)"
  S_SB_ON="SPRAWDZ TO (wlaczony — HAOS nie wystartuje)"
  S_SB_UNK="SPRAWDZ TO (stan nieznany)"
  S_WELCOME="Witaj.\n\nTo narzedzie instaluje najnowszy Home Assistant OS na tym\nkomputerze, bez uzywania wiersza polecen.\n\nSPRAWDZENIE WYMAGAN:\n  Tryb rozruchu : %s\n  Secure Boot   : %s\n\n\"SPRAWDZ TO\" oznacza, ze Home Assistant moze nie wystartowac\npo instalacji. Popraw to w BIOS-ie (Del/F2 przy wlaczaniu).\nNic nie jest zablokowane: mozesz kontynuowac.\n\nNa etapie dysku CALY wybrany dysk zostanie wyczyszczony."
  S_NET_ETH="Szukanie polaczenia przewodowego (Ethernet)..."
  S_SRC_ASK="Skad ma pochodzic obraz?\n\nPobieranie wymaga polaczenia z internetem.\nObraz na pendrive nie wymaga sieci."
  S_SRC_DL="Pobierz najnowsza wersje"
  S_SRC_USE="Uzyj obrazu z pendrive'a"
  S_IMG_SCAN="Szukam obrazow Home Assistant OS na\npodlaczonych pendrive'ach..."
  S_IMG_NONE="Nie znaleziono uzytecznego obrazu.\n\nPlik musi nazywac sie\n  haos_generic-x86-64-<version>.img.xz\n\nZnalezione pliki, nieprzydatne tutaj:\n%s\n\nPodlacz pendrive z wlasciwym obrazem albo\nwroc i pobierz go."
  S_IMG_PICK="Ktory obraz zapisac na dysku?"
  S_IMG_CHECK="Sprawdzam sumy .xz obrazu..."
  S_IMG_BAD="Nie udalo sie zweryfikowac tego obrazu:\n%s\n\n%s\n\nJest uszkodzony, niekompletny albo to nie jest\nplik .img.xz. Na zaden dysk nic nie zapisano."
  S_LAN_ASK="Brak polaczenia sieciowego.\n\nPodlacz kabel Ethernet (LAN) do komputera, a nastepnie\nwybierz PONOW.\n\nBez sieci nie da sie pobrac obrazu.\nNa zadnym dysku nic jeszcze nie zapisano."
  S_LAN_RETRY="Ponow"
  S_LAN_WIFI="Uzyj Wi-Fi"
  S_NET_NOWIFI="Nie wykryto dzialajacej karty Wi-Fi.\n\n%s\n\nPodlacz kabel Ethernet albo uzyj konfiguracji recznej na\nnastepnym ekranie."
  S_NET_SCAN="Skanowanie sieci Wi-Fi..."
  S_NET_PICK="Wybierz siec Wi-Fi:"
  S_NET_RESCAN="[ Skanuj ponownie ]"
  S_NET_RESCAN_D="brak sieci? sprobuj jeszcze raz"
  S_NET_MANUAL="[ Konfiguracja reczna ]"
  S_NET_MANUAL_D="ukryty SSID, WPA enterprise, staly IP (nmtui)"
  S_NET_ETHRETRY="[ Ponow Ethernet ]"
  S_NET_ETHRETRY_D="kabel podlaczony w miedzyczasie"
  S_NET_QUIT="Wyjsc z instalatora?\n\nSiec nie jest skonfigurowana: bez dostepu do internetu\ninstalacja nie moze byc kontynuowana."
  S_NET_PSK="Haslo sieci \"%s\":\n(widoczne, aby uniknac literowek)"
  S_NET_CONN="Laczenie z \"%s\"..."
  S_NET_FAIL="Nie udalo sie polaczyc z \"%s\".\n\n%s\n\nSprawdz haslo albo uzyj konfiguracji recznej."
  S_VER_FETCH="Sprawdzanie najnowszej wersji Home Assistant OS..."
  S_VER_FAIL="Nie udalo sie ustalic wersji Home Assistant OS.\n\nOba zrodla sprawdzone bez powodzenia:\n  version.home-assistant.io  (kanal stable)\n  api.github.com             (najnowsze wydanie)\n\nInstalacja nie moze byc kontynuowana: bez wersji nie ma\nobrazu do pobrania.\n\nSprawdz dostep do internetu i DNS, a nastepnie uruchom\ninstalator ponownie."
  S_VER_NOIMG="Nie znaleziono obrazu dla wersji %s:\n%s"
  S_DISK_NONE="Nie wykryto zadnego dysku wewnetrznego."
  S_DISK_PICK="Na ktorym dysku zainstalowac Home Assistant OS?\nCALA jego zawartosc zostanie trwale usunieta.\n\nDyski oznaczone [!! USB / ZEWNETRZNY !!] sa wyjmowane:\nto prawdopodobnie dysk kopii zapasowych, nie twoj cel."
  S_DISK_SMALL="Dysk %s ma %s GB.\n\nHome Assistant wymaga co najmniej 32 GB. Zapis moze sie nie\nudac albo zostawic zbyt malo miejsca.\n\nNic jeszcze nie zostalo usuniete."
  S_DISK_CONFIRM="Dysk %s zostanie CALKOWICIE WYCZYSZCZONY.\n\nWykryta obecna zawartosc:\n%s\n\nWpisz YES (wielkimi literami), aby go wyczyscic\ni zainstalowac Home Assistant OS.\nKazda inna odpowiedz zatrzymuje wszystko, nic nie zostanie\nusuniete."
  S_CONFIRM_T="⚠  OSTATNIE POTWIERDZENIE"
  S_STOP="Zatrzymaj (zalecane)"
  S_GOON="Kontynuuj mimo to"
  S_STOPPED="Zatrzymano przed jakakolwiek zmiana."
  S_PREP="Przygotowywanie dysku %s..."
  S_WRITING="Pobieranie HAOS %s.\nNie wylaczaj komputera."
  S_WRITE_HEAD="Zapisywanie obrazu na %s.\nNie wylaczaj komputera."
  S_DL_CHECK="Sprawdzanie pobranego obrazu..."
  S_DL_RESUME="Wznawianie pobierania: %s z %s juz na dysku."
  S_DL_RETRY="Pobieranie zostalo przerwane (kod curl %s).\n\nOstatnie linie dziennika:\n%s\n\nKontynuowac od miejsca przerwania?"
  S_DL_ABORT="Pobieranie nie zostalo ukonczone.\n\nNIC NIE ZOSTALO ZAPISANE: dysk jest dokladnie w takim\nstanie jak wczesniej, jego zawartosc nadal tam jest.\n\nSzczegoly:\n%s\n\nPelny dziennik: %s"
  S_DL_BAD="Pobrany obraz jest uszkodzony (sumy kontrolne .xz sie\nnie zgadzaja) — dwa razy z rzedu.\n\nNIC NIE ZOSTALO ZAPISANE: dysk jest nietkniety.\nTo wskazuje na siec lub proxy z pamiecia podreczna,\nnie na dysk.\n\nSzczegoly:\n%s\n\nPelny dziennik: %s"
  S_DISK_HA="⚠  Na tym dysku jest juz instalacja Home Assistant\n   (znaleziono hassos-boot / hassos-data). Wyczyszczenie\n   zniszczy konfiguracje, dodatki i historie."
  S_FMT_TYPE="Wpisz YES, aby sformatowac pendrive.\nKazda inna odpowiedz zostawia go bez zmian."
  S_FAIL="Instalacja nie udala sie (kod %s).\n\nNajczestsza przyczyna: polaczenie z internetem zerwalo sie\npodczas pobierania. Dysk jest juz wyczyszczony; rozpoczecie\nod nowa jest bezpieczne.\n\nSzczegoly:\n%s\n\nPelny dziennik: %s"
  S_VFY_ASK="Sprawdzic, czy dysk zostal zapisany poprawnie?\n\nOdczyt zwrotny %s z %s.\nTrwa 1 do 3 minut w zaleznosci od dysku.\n\nZalecane, zwlaszcza na starszym dysku."
  S_VFY_RUN="Odczyt zwrotny i weryfikacja dysku..."
  S_VFY_OK="Weryfikacja zakonczona pomyslnie.\n\nZawartosc dysku dokladnie odpowiada obrazowi.\n\nSHA256: %s..."
  S_VFY_KO="WERYFIKACJA NIE UDALA SIE\n\nDysk nie odpowiada zapisanemu obrazowi:\n  oczekiwano: %s...\n  odczytano : %s...\n\nPrawdopodobne przyczyny: uszkodzony dysk, kabel SATA,\npamiec.\nNIE uzywaj tej instalacji: sprobuj ponownie, a jesli blad\nsie powtorzy, wymien dysk."
  S_VFY_SKIP="Nie obliczono sumy kontrolnej obrazu: weryfikacja\nniemozliwa.\nInstalacja jest prawie na pewno w porzadku (pobranie jest\nweryfikowane przez sam format skompresowany)."
  S_LOG_ASK="Skopiowac dziennik instalacji na pendrive USB?\n\nInaczej przepadnie po restarcie. To ten plik nalezy\ndolaczyc, zglaszajac problem."
  S_LOG_OK="Dziennik skopiowany do %s\n(plik haos-install-*.log)\n\nMozesz wyjac pendrive."
  S_LOG_MENU="Gdzie zapisac dziennik instalacji?\n\nNie znaleziono automatycznie zadnego nosnika do zapisu.\nWybierz opcje:"
  S_LOG_M_USB="Podlacz pendrive USB"
  S_LOG_M_USB_D="odczekaj 5 s i potwierdz"
  S_LOG_M_FMT="Sformatuj ten pendrive"
  S_LOG_M_FMT_D="usuwa instalator"
  S_LOG_M_SHOW="Pokaz na ekranie"
  S_LOG_M_SHOW_D="aby go sfotografowac"
  S_LOG_M_NONE="Nie zapisuj"
  S_LOG_M_NONE_D="dziennik przepadnie"
  S_LOG_VTOY="Pendrive jest rozpoznany, ale zarezerwowany przez system\nrozruchowy i nie udalo sie go automatycznie zwolnic.\n\nZdarza sie z Ventoy: obraz instalacyjny jest plikiem na tym\npendrivie.\n\n-> ODLACZ i PONOWNIE PODLACZ pendrive, odczekaj 5 sekund\ni wybierz ponizej \"Podlacz pendrive USB\".\n\nInstalator dziala z pamieci: odlaczenie jest bezpieczne."
  S_LOG_RO="Znaleziono nosnik, ale jest tylko do odczytu.\n\nZdarza sie z Ventoy: system instalacyjny uzywa tej partycji,\nwiec nie mozna jej zmienic.\n\nOdlaczenie i ponowne podlaczenie pendrive'a go uwolni,\nalbo wybierz inna opcje."
  S_LOG_DETECT="Wykrywanie nosnikow..."
  S_LOG_RETRY="Nadal nic do zapisu.\n\nPendrive moze nie miec partycji albo jego format nie jest\nrozpoznawany. Mozesz sprobowac innego."
  S_LOG_FULL="Znaleziono nosnik, ale jest pelny.\n\nBrakuje miejsca na dziennik. Podlacz inny pendrive USB\nalbo pokaz dziennik na ekranie w nastepnym kroku, aby go\nsfotografowac."
  S_LOG_NONE="Dziennik nie zostal skopiowany.\n\nNadal mozna go odczytac z powloki:\n  cat %s"
  S_WIFI_PUSH="Siec Wi-Fi \"%s\" skonfigurowana wstepnie.\n\nHome Assistant sprobuje polaczyc sie przy pierwszym\nuruchomieniu — ALE tylko jesli twoja karta Wi-Fi jest wsrod\nobslugiwanych (ta lista jest krotsza niz lista tego\ninstalatora).\n\nJesli po 5 min Home Assistant nie jest online:\n - podlacz kabel Ethernet (zalecane) albo\n - zglos swoja karte projektowi Home Assistant OS.\n\nTrzymaj ten komputer w zasiegu Wi-Fi."
  S_WIFI_PUSH_FAIL="Nie udalo sie wstepnie skonfigurowac Wi-Fi w obrazie.\n\nHome Assistant wystartuje bez sieci: musisz podlaczyc ja\npozniej (kabel Ethernet albo klawiatura i ekran na konsoli\nHAOS)."
  S_WIFI_PUSH_SKIP="Tej sieci Wi-Fi nie da sie skonfigurowac wstepnie.\n\nOpiera sie na certyfikatach lub trybie, ktorego Home\nAssistant nie przejmie w tej postaci. Nic nie zapisano:\nlepiej tak niz siec, ktora nigdy nie wstanie.\n\nCO ZROBIC PO INSTALACJI:\n - podlacz kabel Ethernet (najprosciej) albo\n - skonfiguruj Wi-Fi z konsoli Home Assistant\n   (klawiatura i ekran na komputerze).\n\nSzczegoly sa w dzienniku instalacji."
  S_DONE_LOG="\n\nPendrive zostal sformatowany: to znowu zwykly pendrive USB,\na dziennik instalacji jest na nim zapisany."
  S_FMT_ASK="Sformatowac pendrive instalatora?\n\n%s\n\nStanie sie znowu zwyklym pendrive'em FAT32, uzytecznym\nwszedzie, a dziennik instalacji zostanie na nim zapisany.\n\n⚠  INSTALATOR ZOSTANIE USUNIETY: aby zainstalowac ponownie,\ntrzeba bedzie zapisac pendrive od nowa na innym komputerze.\n\nInstalacja Home Assistant zapisana juz na dysku nie jest\ndotknieta."
  S_FMT_FAIL="Nie udalo sie sformatowac pendrive'a.\n\nNic nie zostalo ruszone: nadal dziala jako instalator.\nSzczegoly sa w dzienniku."
  S_FMT_BROKEN="Formatowanie pendrive'a nie udalo sie do konca.\n\n⚠  Pendrive nie jest juz bootowalny: musisz zapisac go\nponownie, aby uzyc go jako instalatora.\n\nInstalacja Home Assistant na dysku nie jest naruszona,\njest kompletna."
  S_DONE="Instalacja zakonczona.\n\nHome Assistant OS jest zainstalowany na %s.\n\n-> WYJMIJ TERAZ PENDRIVE USB, przed potwierdzeniem.\n   (instalator dziala z pamieci: nie jest juz potrzebny)\n\nDALEJ:\n 1. Potwierdz ponizej: komputer uruchomi Home Assistant.\n 2. Zostaw podlaczony kabel sieciowy.\n 3. Poczekaj 2 do 5 minut (pierwszy start).\n 4. Z innego urzadzenia:  http://homeassistant.local"
  S_UNAT_ACTIVE="Instalacja bezobsługowa.\n\nPlik konfiguracji: %s\nJęzyk: %s\n\nŻadne pytanie nie zostanie zadane."
  S_UNAT_NOWIPE="Instalacja bezobsługowa odrzucona.\n\nBrak WIPE=yes w:\n%s\n\nNic nie zostało zmienione."
  S_UNAT_NODISK="Instalacja bezobsługowa odrzucona.\n\nDISK=%s nie jest tutaj użytecznym dyskiem.\n\nNic nie zostało zmienione."
  S_UNAT_MULTI="Instalacja bezobsługowa odrzucona.\n\nZnaleziono %s użytecznych dysków:\n%s\n\nUstaw DISK= na jeden z nich w pliku konfiguracji.\nNic nie zostało zmienione."
  S_UNAT_NONET="Instalacja bezobsługowa nie powiodła się.\n\nBrak sieci i brak obrazu na pendrivie:\nnie można niczego pobrać.\n\nNic nie zostało zmienione."
  S_UNAT_NOSTAGE="Instalacja bezobsługowa odrzucona.\n\nZa mało wolnego RAM na obraz (%s) i brak\nzapisywalnego nośnika, aby go trzymać.\n\nDodaj STREAM=yes, aby zgodzić się na skasowanie\ndysku przed sprawdzeniem pobrania.\nNic nie zostało zapisane."
  S_UNAT_OFF_REBOOT="Instalacja zakończona.\n\nHome Assistant OS jest zainstalowany na %s.\n\nWyjmij teraz pendrive USB.\nKomputer uruchomi się ponownie za 15 sekund."
  S_UNAT_OFF_HALT="Instalacja zakończona.\n\nHome Assistant OS jest zainstalowany na %s.\n\nWyjmij teraz pendrive USB.\nKomputer wyłączy się za 15 sekund."
  S_UNAT_FAIL="\n\nDziennik widać tutaj i jest zapisany w\n%s.\n\nKomputer wyłączy się za 20 sekund."
;;
sv)
  S_STAGE_ASK="For lite ledigt minne for att halla avbilden i RAM (%s).\nInget skrivbart media med sa mycket ledigt utrymme hittades.\nAnslut ett USB-minne eller en extern disk och valj Forsok igen: avbilden hamtas dit och kontrolleras INNAN nagot raderas.\n\"Skriv i ett genomlop\" raderar i stallet maldisken forst: tappar natverket efterat star du med en tom disk."
  S_STAGE_INFO="For lite minne for att lagga avbilden i RAM.\nDen hamtas till:\n%s\nIngenting skrivs till maldisken forran filen ar komplett och kontrollerad, och den tas bort darifran efterat."
  S_STAGE_RETRY="Forsok igen"
  S_STAGE_STREAM="Skriv i ett genomlop"
  S_TITLE="Installation av Home Assistant OS"
  S_WARN="⚠  VARNING — installation av Home Assistant OS"
  S_RESCUE="\n\nDu kan spara loggen och sedan stanga av datorn."
  S_HALT_ASK="Vad nu?\n\nInget mer andras: installationen misslyckades.\nAtt stanga av ar det normala valet.\n\nTerminalen ar bara anvandbar om du kan den."
  S_HALT_OFF="Stang av datorn"
  S_HALT_SHELL="Oppna en terminal"
  S_CANCELLED="Installationen avbrot."
  S_VFY_ABORT="Disken stammer inte med avbilden: starta inte fran den."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="KONTROLLERA DETTA (Legacy/CSM-lage hittat)"
  S_SB_OFF="OK (avstangt)"
  S_SB_ON="KONTROLLERA DETTA (paslaget — HAOS startar inte)"
  S_SB_UNK="KONTROLLERA DETTA (status okand)"
  S_WELCOME="Valkommen.\n\nDet har verktyget installerar senaste Home Assistant OS pa\ndenna dator, utan kommandorad.\n\nKONTROLL AV KRAV:\n  Startlage   : %s\n  Secure Boot : %s\n\n\"KONTROLLERA DETTA\" betyder att Home Assistant kanske inte\nstartar efter installationen. Atgarda i BIOS (Del/F2 vid\nuppstart). Inget ar blockerat: du kan fortsatta anda.\n\nI disksteget raderas HELA den disk du valjer."
  S_NET_ETH="Soker efter en tradbunden (Ethernet-)anslutning..."
  S_SRC_ASK="Var ska avbildningen komma ifran?\n\nNedladdning kraver en internetanslutning.\nEn avbildning pa ett USB-minne kraver inget nat."
  S_SRC_DL="Ladda ner senaste versionen"
  S_SRC_USE="Anvand en avbildning pa ett USB-minne"
  S_IMG_SCAN="Soker efter Home Assistant OS-avbildningar pa\nde anslutna minnena..."
  S_IMG_NONE="Ingen anvandbar avbildning hittades.\n\nFilen maste heta\n  haos_generic-x86-64-<version>.img.xz\n\nFiler som hittades men inte gar att anvanda:\n%s\n\nSatt i ett minne med ratt avbildning, eller ga\ntillbaka och ladda ner den."
  S_IMG_PICK="Vilken avbildning ska skrivas till disken?"
  S_IMG_CHECK="Kontrollerar avbildningens .xz-kontrollsummor..."
  S_IMG_BAD="Avbildningen kunde inte verifieras:\n%s\n\n%s\n\nDen ar skadad, ofullstandig eller inte en\nriktig .img.xz-fil. Inget har skrivits till\nnagon disk."
  S_LAN_ASK="Ingen natverksanslutning.\n\nAnslut en Ethernetkabel (LAN) till datorn och valj\nForsok igen.\n\nUtan natverk kan avbilden inte hamtas.\nInget har skrivits till nagon disk an."
  S_LAN_RETRY="Forsok igen"
  S_LAN_WIFI="Anvand Wi-Fi i stallet"
  S_NET_NOWIFI="Ingen anvandbar Wi-Fi-adapter hittades.\n\n%s\n\nAnslut en Ethernetkabel eller anvand manuell konfiguration\npa nasta skarm."
  S_NET_SCAN="Soker efter Wi-Fi-natverk..."
  S_NET_PICK="Valj ditt Wi-Fi-natverk:"
  S_NET_RESCAN="[ Sok igen ]"
  S_NET_RESCAN_D="inget natverk? forsok igen"
  S_NET_MANUAL="[ Manuell konfiguration ]"
  S_NET_MANUAL_D="dolt SSID, WPA enterprise, fast IP (nmtui)"
  S_NET_ETHRETRY="[ Forsok Ethernet igen ]"
  S_NET_ETHRETRY_D="kabel ansluten under tiden"
  S_NET_QUIT="Avsluta installationsprogrammet?\n\nInget natverk ar konfigurerat: installationen kan inte\nfortsatta utan internet."
  S_NET_PSK="Losenord for natverket \"%s\":\n(visas i klartext for att undvika skrivfel)"
  S_NET_CONN="Ansluter till \"%s\"..."
  S_NET_FAIL="Kunde inte ansluta till \"%s\".\n\n%s\n\nKontrollera losenordet eller anvand manuell konfiguration."
  S_VER_FETCH="Slar upp senaste versionen av Home Assistant OS..."
  S_VER_FAIL="Kunde inte faststalla versionen av Home Assistant OS.\n\nBada kallorna provades utan framgang:\n  version.home-assistant.io  (stable-kanalen)\n  api.github.com             (senaste utgavan)\n\nInstallationen kan inte fortsatta: utan version finns ingen\navbild att hamta.\n\nKontrollera internet och DNS, och starta sedan\ninstallationsprogrammet igen."
  S_VER_NOIMG="Ingen avbild hittades for version %s:\n%s"
  S_DISK_NONE="Ingen intern disk hittades."
  S_DISK_PICK="Vilken disk ska Home Assistant OS installeras pa?\nALLT innehall raderas permanent.\n\nDiskar markta [!! USB / EXTERN !!] ar flyttbara: det ar\nformodligen en sakerhetskopiedisk, inte ditt mal."
  S_DISK_SMALL="Disken %s ar %s GB.\n\nHome Assistant behover minst 32 GB. Skrivningen kan\nmisslyckas eller lamna for lite plats.\n\nInget har raderats an."
  S_DISK_CONFIRM="Disken %s raderas HELT.\n\nNuvarande innehall hittat:\n%s\n\nSkriv YES (med versaler) for att radera den och installera\nHome Assistant OS.\nAlla andra svar stoppar har, utan att nagot raderas."
  S_CONFIRM_T="⚠  SISTA BEKRAFTELSE"
  S_STOP="Stoppa (rekommenderas)"
  S_GOON="Fortsatt anda"
  S_STOPPED="Stoppat innan nagot andrades."
  S_PREP="Forbereder disken %s..."
  S_WRITING="Hamtar HAOS %s.\nStang inte av datorn."
  S_WRITE_HEAD="Skriver avbilden till %s.\nStang inte av datorn."
  S_DL_CHECK="Kontrollerar den hamtade avbilden..."
  S_DL_RESUME="Aterupptar hamtningen: %s av %s finns redan pa disken."
  S_DL_RETRY="Hamtningen stoppade (curl-kod %s).\n\nSenaste loggraderna:\n%s\n\nFortsatt dar den stannade?"
  S_DL_ABORT="Hamtningen slutfordes inte.\n\nINGET SKREVS: disken ar precis som den var och innehallet\nfinns kvar.\n\nDetalj:\n%s\n\nFull logg: %s"
  S_DL_BAD="Den hamtade avbilden ar skadad (.xz-kontrollsummorna\nstammer inte) — tva ganger i rad.\n\nINGET SKREVS: disken ar orord.\nDet pekar pa natverket eller en cacheproxy, inte disken.\n\nDetalj:\n%s\n\nFull logg: %s"
  S_DISK_HA="⚠  Disken innehaller redan en Home Assistant-installation\n   (hassos-boot / hassos-data hittades). Radering forstor din\n   konfiguration, dina tillagg och din historik."
  S_FMT_TYPE="Skriv YES for att formatera minnet.\nAlla andra svar lamnar det som det ar."
  S_FAIL="Installationen misslyckades (kod %s).\n\nVanligaste orsaken: internetanslutningen brots under\nhamtningen. Disken ar redan raderad; att borja om fran\nborjan ar sakert.\n\nDetaljer:\n%s\n\nFull logg: %s"
  S_VFY_ASK="Kontrollera att disken skrevs korrekt?\n\nLaser tillbaka %s fran %s.\nTar 1 till 3 minuter beroende pa disk.\n\nRekommenderas, sarskilt pa en aldre disk."
  S_VFY_RUN="Laser tillbaka och kontrollerar disken..."
  S_VFY_OK="Kontrollen gick igenom.\n\nDiskens innehall stammer exakt med avbilden.\n\nSHA256: %s..."
  S_VFY_KO="KONTROLLEN MISSLYCKADES\n\nDisken stammer inte med den skrivna avbilden:\n  forvantat: %s...\n  last     : %s...\n\nTroliga orsaker: trasig disk, SATA-kabel, minne.\nANVAND INTE denna installation: forsok igen och byt disk om\nfelet kvarstar."
  S_VFY_SKIP="Avbildens kontrollsumma beraknades inte: kan inte\nkontrollera.\nInstallationen ar med stor sannolikhet korrekt (hamtningen\nvalideras av det komprimerade formatet sjalvt)."
  S_LOG_ASK="Kopiera installationsloggen till ett USB-minne?\n\nAnnars forsvinner den vid omstart. Det ar filen som ska\nbifogas nar du rapporterar problemet."
  S_LOG_OK="Loggen kopierades till %s\n(filen haos-install-*.log)\n\nDu kan ta ut minnet."
  S_LOG_MENU="Var ska installationsloggen sparas?\n\nInget skrivbart media hittades automatiskt.\nValj ett alternativ:"
  S_LOG_M_USB="Anslut ett USB-minne"
  S_LOG_M_USB_D="vanta 5 s och bekrafta"
  S_LOG_M_FMT="Formatera detta minne"
  S_LOG_M_FMT_D="raderar installationsprogrammet"
  S_LOG_M_SHOW="Visa pa skarmen"
  S_LOG_M_SHOW_D="for att fotografera den"
  S_LOG_M_NONE="Spara inte"
  S_LOG_M_NONE_D="loggen forsvinner"
  S_LOG_VTOY="Minnet kanned igen, men ar reserverat av startsystemet\noch kunde inte frigoras automatiskt.\n\nDet hander med Ventoy: installationsavbilden ar en fil pa\ndetta minne.\n\n-> KOPPLA UR och sedan I minnet igen, vanta 5 sekunder och\n   valj \"Anslut ett USB-minne\" nedan.\n\nInstallationsprogrammet kors fran minnet: att koppla ur ar\nofarligt."
  S_LOG_RO="Ett media hittades, men det ar skrivskyddat.\n\nDet hander med Ventoy: installationssystemet anvander den\npartitionen, sa den kan inte andras.\n\nAtt koppla ur och i minnet igen frigor det, eller valj ett\nannat alternativ."
  S_LOG_DETECT="Soker efter media..."
  S_LOG_RETRY="Fortfarande inget skrivbart.\n\nMinnet kanske saknar partitioner eller har ett format som\ninte kanned igen. Du kan prova ett annat."
  S_LOG_FULL="Ett media hittades, men det ar fullt.\n\nDet finns inte plats for loggen. Anslut ett annat\nUSB-minne, eller visa loggen pa skarmen i nasta steg for\natt fotografera den."
  S_LOG_NONE="Loggen kopierades inte.\n\nDen gar fortfarande att lasa fran skalet:\n  cat %s"
  S_WIFI_PUSH="Wi-Fi-natverket \"%s\" ar forkonfigurerat.\n\nHome Assistant forsoker ansluta vid forsta starten — MEN\nbara om ditt Wi-Fi-kort finns bland dem det stoder (den\nlistan ar kortare an det har programmets).\n\nOm Home Assistant inte ar online efter 5 min:\n - anslut en Ethernetkabel (rekommenderas), eller\n - rapportera ditt kort till Home Assistant OS-projektet.\n\nHall datorn inom Wi-Fi-rackvidd."
  S_WIFI_PUSH_FAIL="Wi-Fi kunde inte forkonfigureras i avbilden.\n\nHome Assistant startar utan natverk: du far ansluta det\nefterat (Ethernetkabel, eller tangentbord och skarm pa\nHAOS-konsolen)."
  S_WIFI_PUSH_SKIP="Detta Wi-Fi-natverk kan inte forkonfigureras.\n\nDet bygger pa certifikat eller ett lage som Home Assistant\ninte kan ta over som det ar. Inget skrevs: battre det an\nett natverk som aldrig kommer upp.\n\nGOR EFTER INSTALLATIONEN:\n - anslut en Ethernetkabel (enklast), eller\n - konfigurera Wi-Fi fran Home Assistant-konsolen\n   (tangentbord och skarm pa datorn).\n\nDetaljerna finns i installationsloggen."
  S_DONE_LOG="\n\nMinnet formaterades: det ar ett vanligt USB-minne igen och\ninstallationsloggen ligger pa det."
  S_FMT_ASK="Formatera installationsminnet?\n\n%s\n\nDet blir ett vanligt FAT32-minne igen, anvandbart\noverallt, och installationsloggen kopieras dit.\n\n⚠  INSTALLATIONSPROGRAMMET RADERAS: for att installera om\nmaste minnet skrivas pa nytt fran en annan dator.\n\nDen Home Assistant-installation som redan skrivits till\ndisken paverkas inte."
  S_FMT_FAIL="Minnet kunde inte formateras.\n\nInget rordes: det gar fortfarande att anvanda som\ninstallationsprogram. Detaljerna finns i loggen."
  S_FMT_BROKEN="Formateringen av minnet misslyckades halvvags.\n\n⚠  Minnet gar inte langre att starta fran: du maste skriva\nom det for att anvanda det som installationsprogram.\n\nHome Assistant-installationen pa disken paverkas inte, den\nar komplett."
  S_DONE="Installationen ar klar.\n\nHome Assistant OS ar installerat pa %s.\n\n-> TA UT USB-MINNET NU, innan du bekraftar.\n   (programmet kors fran minnet: det behovs inte langre)\n\nNASTA:\n 1. Bekrafta nedan: datorn startar om i Home Assistant.\n 2. Lat natverkskabeln sitta kvar.\n 3. Vanta 2 till 5 minuter (forsta starten).\n 4. Fran en annan enhet:  http://homeassistant.local"
  S_UNAT_ACTIVE="Obevakad installation.\n\nKonfigurationsfil: %s\nSpråk: %s\n\nIngen fråga kommer att ställas."
  S_UNAT_NOWIPE="Obevakad installation nekad.\n\nWIPE=yes saknas i:\n%s\n\nInget har ändrats."
  S_UNAT_NODISK="Obevakad installation nekad.\n\nDISK=%s är ingen användbar disk här.\n\nInget har ändrats."
  S_UNAT_MULTI="Obevakad installation nekad.\n\nHittade %s användbara diskar:\n%s\n\nSätt DISK= till en av dem i konfigurationsfilen.\nInget har ändrats."
  S_UNAT_NONET="Obevakad installation misslyckades.\n\nInget nätverk och ingen image på ett minne:\ninget kan hämtas.\n\nInget har ändrats."
  S_UNAT_NOSTAGE="Obevakad installation nekad.\n\nFör lite ledigt RAM för imagen (%s) och inget\nskrivbart medium att lägga den på.\n\nLägg till STREAM=yes för att acceptera att disken\nraderas före kontrollen av nedladdningen.\nInget har skrivits."
  S_UNAT_OFF_REBOOT="Installationen är klar.\n\nHome Assistant OS är installerat på %s.\n\nTa ut USB-minnet nu.\nDatorn startar om inom 15 sekunder."
  S_UNAT_OFF_HALT="Installationen är klar.\n\nHome Assistant OS är installerat på %s.\n\nTa ut USB-minnet nu.\nDatorn stängs av inom 15 sekunder."
  S_UNAT_FAIL="\n\nLoggen visas här och sparas i\n%s.\n\nDatorn stängs av inom 20 sekunder."
;;
pt)
  S_STAGE_ASK="Memoria livre insuficiente para manter a imagem em RAM (%s).\nNao foi encontrado nenhum suporte de escrita com esse espaco livre.\nLigue uma pen ou um disco externo e escolha Repetir: a imagem e descarregada para la e verificada ANTES de apagar seja o que for.\n\"Escrever de uma so vez\" apaga primeiro o disco de destino: se a rede cair depois, fica um disco vazio."
  S_STAGE_INFO="Memoria insuficiente para colocar a imagem em RAM.\nE descarregada para:\n%s\nNada e escrito no disco de destino enquanto o ficheiro nao estiver completo e verificado, e depois e apagado de la."
  S_STAGE_RETRY="Repetir"
  S_STAGE_STREAM="Escrever de uma so vez"
  S_TITLE="Instalacao do Home Assistant OS"
  S_WARN="⚠  AVISO — instalacao do Home Assistant OS"
  S_RESCUE="\n\nVai poder guardar o registo e depois desligar o PC."
  S_HALT_ASK="E agora?\n\nNada mais vai mudar: a instalacao falhou.\nDesligar e a escolha normal.\n\nO terminal so serve se souber trabalhar com ele."
  S_HALT_OFF="Desligar o PC"
  S_HALT_SHELL="Abrir um terminal"
  S_CANCELLED="Instalacao cancelada."
  S_VFY_ABORT="O disco nao corresponde a imagem: nao arranque a partir dele."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="VERIFIQUE ISTO (modo Legacy/CSM detetado)"
  S_SB_OFF="OK (desativado)"
  S_SB_ON="VERIFIQUE ISTO (ativado — o HAOS nao arranca)"
  S_SB_UNK="VERIFIQUE ISTO (estado desconhecido)"
  S_WELCOME="Bem-vindo.\n\nEsta ferramenta instala a versao mais recente do Home\nAssistant OS neste PC, sem linha de comandos.\n\nVERIFICACAO DOS REQUISITOS:\n  Modo de arranque : %s\n  Secure Boot      : %s\n\n\"VERIFIQUE ISTO\" significa que o Home Assistant pode nao\narrancar apos a instalacao. Corrija na BIOS (Del/F2 ao\nligar). Nada esta bloqueado: pode continuar.\n\nNo passo do disco, TODO o disco escolhido sera apagado."
  S_NET_ETH="A procurar uma ligacao por cabo (Ethernet)..."
  S_SRC_ASK="De onde deve vir a imagem?\n\nTransferir exige ligacao a Internet. Uma\nimagem numa pen USB nao precisa de rede."
  S_SRC_DL="Transferir a versao mais recente"
  S_SRC_USE="Usar uma imagem numa pen USB"
  S_IMG_SCAN="A procurar imagens do Home Assistant OS nas\npens ligadas..."
  S_IMG_NONE="Nenhuma imagem utilizavel encontrada.\n\nO ficheiro tem de se chamar\n  haos_generic-x86-64-<version>.img.xz\n\nFicheiros encontrados mas inutilizaveis aqui:\n%s\n\nLiga uma pen com a imagem certa, ou volta\natras e transfere-a."
  S_IMG_PICK="Que imagem deve ser escrita no disco?"
  S_IMG_CHECK="A verificar as somas .xz da imagem..."
  S_IMG_BAD="Nao foi possivel verificar esta imagem:\n%s\n\n%s\n\nEsta danificada, incompleta, ou nao e mesmo um\nficheiro .img.xz. Nada foi escrito em disco\nalgum."
  S_LAN_ASK="Sem ligacao de rede.\n\nLigue um cabo Ethernet (LAN) ao PC e escolha\nRepetir.\n\nSem rede nao e possivel descarregar a imagem.\nAinda nada foi escrito em nenhum disco."
  S_LAN_RETRY="Repetir"
  S_LAN_WIFI="Usar Wi-Fi"
  S_NET_NOWIFI="Nenhum adaptador Wi-Fi utilizavel detetado.\n\n%s\n\nLigue um cabo Ethernet ou use a configuracao manual no\necra seguinte."
  S_NET_SCAN="A procurar redes Wi-Fi..."
  S_NET_PICK="Escolha a sua rede Wi-Fi:"
  S_NET_RESCAN="[ Procurar novamente ]"
  S_NET_RESCAN_D="nao aparece? tentar de novo"
  S_NET_MANUAL="[ Configuracao manual ]"
  S_NET_MANUAL_D="SSID oculto, WPA enterprise, IP fixo (nmtui)"
  S_NET_ETHRETRY="[ Repetir Ethernet ]"
  S_NET_ETHRETRY_D="cabo ligado entretanto"
  S_NET_QUIT="Sair do instalador?\n\nNenhuma rede esta configurada: a instalacao nao pode\ncontinuar sem acesso a Internet."
  S_NET_PSK="Palavra-passe da rede \"%s\":\n(visivel para evitar erros de escrita)"
  S_NET_CONN="A ligar a \"%s\"..."
  S_NET_FAIL="Nao foi possivel ligar a \"%s\".\n\n%s\n\nVerifique a palavra-passe ou use a configuracao manual."
  S_VER_FETCH="A procurar a versao mais recente do Home Assistant OS..."
  S_VER_FAIL="Nao foi possivel determinar a versao do Home Assistant OS.\n\nAmbas as fontes foram tentadas sem sucesso:\n  version.home-assistant.io  (canal stable)\n  api.github.com             (ultima versao)\n\nA instalacao nao pode continuar: sem versao nao ha imagem\npara descarregar.\n\nVerifique o acesso a Internet e o DNS e volte a iniciar o\ninstalador."
  S_VER_NOIMG="Nenhuma imagem encontrada para a versao %s:\n%s"
  S_DISK_NONE="Nenhum disco interno detetado."
  S_DISK_PICK="Em que disco deve ser instalado o Home Assistant OS?\nTODO o conteudo sera apagado definitivamente.\n\nOs discos marcados [!! USB / EXTERNO !!] sao amoviveis:\nprovavelmente e um disco de copias, nao o seu destino."
  S_DISK_SMALL="O disco %s tem %s GB.\n\nO Home Assistant precisa de 32 GB no minimo. A escrita pode\nfalhar ou deixar espaco demasiado reduzido.\n\nAinda nada foi apagado."
  S_DISK_CONFIRM="O disco %s vai ser TOTALMENTE APAGADO.\n\nConteudo atual detetado:\n%s\n\nEscreva YES (em maiusculas) para o apagar e instalar o\nHome Assistant OS.\nQualquer outra resposta para aqui, sem apagar nada."
  S_CONFIRM_T="⚠  CONFIRMACAO FINAL"
  S_STOP="Parar (recomendado)"
  S_GOON="Continuar mesmo assim"
  S_STOPPED="Parado antes de qualquer alteracao."
  S_PREP="A preparar o disco %s..."
  S_WRITING="A descarregar o HAOS %s.\nNao desligue o PC."
  S_WRITE_HEAD="A escrever a imagem em %s.\nNao desligue o PC."
  S_DL_CHECK="A verificar a imagem descarregada..."
  S_DL_RESUME="A retomar a descarga: %s de %s ja no disco."
  S_DL_RETRY="A descarga parou (codigo curl %s).\n\nUltimas linhas do registo:\n%s\n\nContinuar de onde parou?"
  S_DL_ABORT="A descarga nao foi concluida.\n\nNADA FOI ESCRITO: o disco esta exatamente como estava e o\nseu conteudo continua la.\n\nDetalhe:\n%s\n\nRegisto completo: %s"
  S_DL_BAD="A imagem descarregada esta corrompida (as somas de\ncontrolo .xz nao coincidem) — duas vezes seguidas.\n\nNADA FOI ESCRITO: o disco esta intacto.\nIsso aponta para a rede ou para um proxy com cache, nao\npara o disco.\n\nDetalhe:\n%s\n\nRegisto completo: %s"
  S_DISK_HA="⚠  Este disco ja contem uma instalacao do Home Assistant\n   (hassos-boot / hassos-data encontrados). Apaga-lo destroi\n   a sua configuracao, os extras e o historico."
  S_FMT_TYPE="Escreva YES para formatar a pen USB.\nQualquer outra resposta deixa-a como esta."
  S_FAIL="A instalacao falhou (codigo %s).\n\nCausa mais comum: a ligacao a Internet caiu durante a\ndescarga. O disco ja esta apagado; comecar de novo e seguro.\n\nDetalhes:\n%s\n\nRegisto completo: %s"
  S_VFY_ASK="Verificar se o disco foi escrito corretamente?\n\nRele %s a partir de %s.\nDemora 1 a 3 minutos conforme o disco.\n\nRecomendado, sobretudo num disco antigo."
  S_VFY_RUN="A reler e verificar o disco..."
  S_VFY_OK="Verificacao concluida com exito.\n\nO conteudo do disco corresponde exatamente a imagem.\n\nSHA256: %s..."
  S_VFY_KO="VERIFICACAO FALHOU\n\nO disco nao corresponde a imagem escrita:\n  esperado: %s...\n  lido    : %s...\n\nCausas provaveis: disco avariado, cabo SATA, memoria.\nNAO use esta instalacao: tente de novo e, se o erro\npersistir, substitua o disco."
  S_VFY_SKIP="A soma de controlo da imagem nao foi calculada: nao e\npossivel verificar.\nA instalacao esta quase certamente bem (a descarga e\nvalidada pelo proprio formato comprimido)."
  S_LOG_ASK="Copiar o registo da instalacao para uma pen USB?\n\nCaso contrario perde-se no reinicio. E o ficheiro a anexar\nquando reportar o problema."
  S_LOG_OK="Registo copiado para %s\n(ficheiro haos-install-*.log)\n\nJa pode retirar a pen."
  S_LOG_MENU="Onde guardar o registo da instalacao?\n\nNenhum suporte de escrita foi encontrado\nautomaticamente. Escolha uma opcao:"
  S_LOG_M_USB="Ligar uma pen USB"
  S_LOG_M_USB_D="aguarde 5 s e confirme"
  S_LOG_M_FMT="Formatar esta pen"
  S_LOG_M_FMT_D="apaga o instalador"
  S_LOG_M_SHOW="Mostrar no ecra"
  S_LOG_M_SHOW_D="para a fotografar"
  S_LOG_M_NONE="Nao guardar"
  S_LOG_M_NONE_D="o registo sera perdido"
  S_LOG_VTOY="A pen e reconhecida, mas esta reservada pelo sistema de\narranque e nao foi possivel liberta-la automaticamente.\n\nAcontece com o Ventoy: a imagem de instalacao e um ficheiro\nnesta pen.\n\n-> DESLIGUE e volte a LIGAR a pen, aguarde 5 segundos e\nescolha \"Ligar uma pen USB\" abaixo.\n\nO instalador corre em memoria: desliga-la e inofensivo."
  S_LOG_RO="Foi encontrado um suporte, mas e so de leitura.\n\nAcontece com o Ventoy: o sistema de instalacao esta a usar\nessa particao, por isso nao pode ser alterada.\n\nDesligar e voltar a ligar a pen liberta-a, ou escolha outra\nopcao."
  S_LOG_DETECT="A detetar suportes..."
  S_LOG_RETRY="Continua a nao haver nada onde escrever.\n\nA pen pode nao ter particoes ou o formato nao e\nreconhecido. Pode tentar outra."
  S_LOG_FULL="Foi encontrado um suporte, mas esta cheio.\n\nNao ha espaco para o registo. Ligue outra pen USB, ou mostre\no registo no ecra no passo seguinte para o fotografar."
  S_LOG_NONE="Registo nao copiado.\n\nContinua legivel a partir da shell:\n  cat %s"
  S_WIFI_PUSH="Rede Wi-Fi \"%s\" pre-configurada.\n\nO Home Assistant vai tentar ligar-se no primeiro arranque —\nMAS so se a sua placa Wi-Fi estiver entre as suportadas (a\nlista dele e mais curta do que a deste instalador).\n\nSe o Home Assistant nao estiver online apos 5 min:\n - ligue um cabo Ethernet (recomendado), ou\n - reporte a sua placa ao projeto Home Assistant OS.\n\nMantenha este PC ao alcance do Wi-Fi."
  S_WIFI_PUSH_FAIL="Nao foi possivel pre-configurar o Wi-Fi na imagem.\n\nO Home Assistant arranca sem rede: tera de a ligar depois\n(cabo Ethernet, ou teclado e ecra na consola do HAOS)."
  S_WIFI_PUSH_SKIP="Esta rede Wi-Fi nao pode ser pre-configurada.\n\nDepende de certificados ou de um modo que o Home Assistant\nnao consegue assumir tal como esta. Nada foi escrito:\nmelhor isso do que uma rede que nunca aparece.\n\nFAZER APOS A INSTALACAO:\n - ligue um cabo Ethernet (mais simples), ou\n - configure o Wi-Fi a partir da consola do Home Assistant\n   (teclado e ecra no PC).\n\nOs detalhes estao no registo da instalacao."
  S_DONE_LOG="\n\nA pen foi formatada: e outra vez uma pen USB normal e o\nregisto da instalacao ficou la gravado."
  S_FMT_ASK="Formatar a pen USB do instalador?\n\n%s\n\nVoltaria a ser uma pen FAT32 normal, utilizavel em\nqualquer lado, e o registo da instalacao seria copiado para\nla.\n\n⚠  O INSTALADOR SERA APAGADO: para reinstalar teria de\ngravar a pen de novo a partir de outro computador.\n\nA instalacao do Home Assistant ja escrita no disco nao e\nafetada."
  S_FMT_FAIL="Nao foi possivel formatar a pen.\n\nNada foi tocado: continua utilizavel como instalador.\nOs detalhes estao no registo."
  S_FMT_BROKEN="A formatacao da pen falhou a meio.\n\n⚠  A pen ja nao arranca: tera de a gravar de novo para a\nreutilizar como instalador.\n\nA instalacao do Home Assistant no disco nao foi afetada,\nesta completa."
  S_DONE="Instalacao concluida.\n\nO Home Assistant OS esta instalado em %s.\n\n-> RETIRE AGORA A PEN USB, antes de confirmar.\n   (o instalador corre em memoria: ja nao e usada)\n\nSEGUINTE:\n 1. Confirme abaixo: o PC reinicia no Home Assistant.\n 2. Mantenha o cabo de rede ligado.\n 3. Aguarde 2 a 5 minutos (primeiro arranque).\n 4. A partir de outro dispositivo:  http://homeassistant.local"
  S_UNAT_ACTIVE="Instalação sem assistência.\n\nFicheiro de configuração: %s\nIdioma: %s\n\nNenhuma pergunta será feita."
  S_UNAT_NOWIPE="Instalação sem assistência recusada.\n\nFalta WIPE=yes em:\n%s\n\nNada foi alterado."
  S_UNAT_NODISK="Instalação sem assistência recusada.\n\nDISK=%s não é um disco utilizável aqui.\n\nNada foi alterado."
  S_UNAT_MULTI="Instalação sem assistência recusada.\n\nEncontrados %s discos utilizáveis:\n%s\n\nDefina DISK= num deles no ficheiro de\nconfiguração. Nada foi alterado."
  S_UNAT_NONET="A instalação sem assistência falhou.\n\nSem rede e sem imagem numa pen:\nnão é possível descarregar nada.\n\nNada foi alterado."
  S_UNAT_NOSTAGE="Instalação sem assistência recusada.\n\nPouca RAM livre para a imagem (%s) e nenhum\nsuporte gravável onde a guardar.\n\nAcrescente STREAM=yes para aceitar apagar o disco\nantes de verificar a transferência.\nNada foi escrito."
  S_UNAT_OFF_REBOOT="Instalação concluída.\n\nO Home Assistant OS está instalado em %s.\n\nRetire a pen USB agora.\nO PC reinicia dentro de 15 segundos."
  S_UNAT_OFF_HALT="Instalação concluída.\n\nO Home Assistant OS está instalado em %s.\n\nRetire a pen USB agora.\nO PC desliga-se dentro de 15 segundos."
  S_UNAT_FAIL="\n\nO registo aparece aqui e é guardado em\n%s.\n\nO PC desliga-se dentro de 20 segundos."
;;
ru)
  S_STAGE_ASK="Недостаточно свободной памяти, чтобы держать образ в ОЗУ (%s).\nНе найден носитель для записи с таким объёмом свободного места.\nПодключите флешку или внешний диск и выберите Повторить: образ будет скачан туда и проверен ДО того, как что-либо будет стёрто.\n\"Запись в один проход\" наоборот сначала стирает целевой диск: если после этого пропадёт сеть, останется пустой диск."
  S_STAGE_INFO="Недостаточно памяти, чтобы разместить образ в ОЗУ.\nОн скачивается в:\n%s\nНа целевой диск ничего не пишется, пока файл не будет полностью скачан и проверен; после записи он оттуда удаляется."
  S_STAGE_RETRY="Повторить"
  S_STAGE_STREAM="Запись в один проход"
  S_TITLE="Установка Home Assistant OS"
  S_WARN="⚠  ВНИМАНИЕ — установка Home Assistant OS"
  S_RESCUE="\n\nВы сможете сохранить журнал, а затем выключить компьютер."
  S_HALT_ASK="Что дальше?\n\nБольше ничего не изменится: установка завершилась\nнеудачей. Выключение — обычный выбор.\n\nТерминал полезен, только если вы умеете с ним работать."
  S_HALT_OFF="Выключить компьютер"
  S_HALT_SHELL="Открыть терминал"
  S_CANCELLED="Установка отменена."
  S_VFY_ABORT="Диск не совпадает с образом: не загружайтесь с него."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="ПРОВЕРЬТЕ ЭТО (обнаружен режим Legacy/CSM)"
  S_SB_OFF="OK (отключён)"
  S_SB_ON="ПРОВЕРЬТЕ ЭТО (включён — HAOS не загрузится)"
  S_SB_UNK="ПРОВЕРЬТЕ ЭТО (состояние неизвестно)"
  S_WELCOME="Добро пожаловать.\n\nЭта программа устанавливает последнюю версию Home\nAssistant OS на этот компьютер, без командной строки.\n\nПРОВЕРКА ТРЕБОВАНИЙ:\n  Режим загрузки : %s\n  Secure Boot    : %s\n\n«ПРОВЕРЬТЕ ЭТО» значит, что Home Assistant может не\nзагрузиться после установки. Исправляется в BIOS\n(Del/F2 при включении). Ничего не заблокировано:\nможно продолжить.\n\nНа шаге с диском ВЕСЬ выбранный диск будет стёрт."
  S_NET_ETH="Поиск проводного подключения (Ethernet)..."
  S_SRC_ASK="Откуда взять образ?\n\nЗагрузка требует подключения к интернету.\nОбраз на флешке не требует сети."
  S_SRC_DL="Скачать последнюю версию"
  S_SRC_USE="Использовать образ на флешке"
  S_IMG_SCAN="Ищу образы Home Assistant OS на\nподключённых флешках..."
  S_IMG_NONE="Подходящий образ не найден.\n\nФайл должен называться\n  haos_generic-x86-64-<version>.img.xz\n\nНайдены файлы, непригодные здесь:\n%s\n\nВставьте флешку с нужным образом или\nвернитесь и скачайте его."
  S_IMG_PICK="Какой образ записать на диск?"
  S_IMG_CHECK="Проверяю контрольные суммы .xz образа..."
  S_IMG_BAD="Не удалось проверить этот образ:\n%s\n\n%s\n\nОн повреждён, неполон или это не файл\n.img.xz. На диск ничего не записано."
  S_LAN_ASK="Нет подключения к сети.\n\nПодключите кабель Ethernet (LAN) к компьютеру, затем\nвыберите Повторить.\n\nБез сети образ невозможно скачать.\nНа диски пока ничего не записано."
  S_LAN_RETRY="Повторить"
  S_LAN_WIFI="Использовать Wi-Fi"
  S_NET_NOWIFI="Не найден работающий адаптер Wi-Fi.\n\n%s\n\nПодключите кабель Ethernet или используйте ручную\nнастройку на следующем экране."
  S_NET_SCAN="Поиск сетей Wi-Fi..."
  S_NET_PICK="Выберите сеть Wi-Fi:"
  S_NET_RESCAN="[ Искать снова ]"
  S_NET_RESCAN_D="нет сети? повторить"
  S_NET_MANUAL="[ Ручная настройка ]"
  S_NET_MANUAL_D="скрытый SSID, WPA enterprise, статический IP (nmtui)"
  S_NET_ETHRETRY="[ Повторить Ethernet ]"
  S_NET_ETHRETRY_D="кабель подключён за это время"
  S_NET_QUIT="Выйти из установщика?\n\nСеть не настроена: без доступа в интернет установка\nне может продолжаться."
  S_NET_PSK="Пароль сети \"%s\":\n(показан открыто, чтобы избежать опечаток)"
  S_NET_CONN="Подключение к \"%s\"..."
  S_NET_FAIL="Не удалось подключиться к \"%s\".\n\n%s\n\nПроверьте пароль или используйте ручную настройку."
  S_VER_FETCH="Поиск последней версии Home Assistant OS..."
  S_VER_FAIL="Не удалось определить версию Home Assistant OS.\n\nОба источника проверены без успеха:\n  version.home-assistant.io  (канал stable)\n  api.github.com             (последний выпуск)\n\nУстановка не может продолжаться: без версии нет образа\nдля скачивания.\n\nПроверьте доступ в интернет и DNS, затем запустите\nустановщик снова."
  S_VER_NOIMG="Образ для версии %s не найден:\n%s"
  S_DISK_NONE="Внутренние диски не найдены."
  S_DISK_PICK="На какой диск установить Home Assistant OS?\nВСЁ его содержимое будет безвозвратно стёрто.\n\nДиски с пометкой [!! USB / ВНЕШНИЙ !!] съёмные: скорее\nвсего это диск для резервных копий, а не ваша цель."
  S_DISK_SMALL="Диск %s имеет размер %s ГБ.\n\nHome Assistant требует минимум 32 ГБ. Запись может\nне удаться или оставить слишком мало места.\n\nПока ничего не стёрто."
  S_DISK_CONFIRM="Диск %s будет ПОЛНОСТЬЮ СТЁРТ.\n\nОбнаружено текущее содержимое:\n%s\n\nВведите YES (заглавными), чтобы стереть его и\nустановить Home Assistant OS.\nЛюбой другой ответ остановит всё, ничего не стирая."
  S_CONFIRM_T="⚠  ОКОНЧАТЕЛЬНОЕ ПОДТВЕРЖДЕНИЕ"
  S_STOP="Остановить (рекомендуется)"
  S_GOON="Всё равно продолжить"
  S_STOPPED="Остановлено до любых изменений."
  S_PREP="Подготовка диска %s..."
  S_WRITING="Скачивание HAOS %s.\nНе выключайте компьютер."
  S_WRITE_HEAD="Запись образа на %s.\nНе выключайте компьютер."
  S_DL_CHECK="Проверка скачанного образа..."
  S_DL_RESUME="Продолжение скачивания: %s из %s уже на диске."
  S_DL_RETRY="Скачивание остановилось (код curl %s).\n\nПоследние строки журнала:\n%s\n\nПродолжить с места остановки?"
  S_DL_ABORT="Скачивание не завершено.\n\nНИЧЕГО НЕ ЗАПИСАНО: диск точно в прежнем состоянии,\nего содержимое на месте.\n\nПодробности:\n%s\n\nПолный журнал: %s"
  S_DL_BAD="Скачанный образ повреждён (контрольные суммы .xz не\nсовпадают) — дважды подряд.\n\nНИЧЕГО НЕ ЗАПИСАНО: диск не тронут.\nЭто указывает на сеть или кэширующий прокси, а не на диск.\n\nПодробности:\n%s\n\nПолный журнал: %s"
  S_DISK_HA="⚠  На этом диске уже есть установка Home Assistant\n   (найдены hassos-boot / hassos-data). Стирание уничтожит\n   конфигурацию, дополнения и историю."
  S_FMT_TYPE="Введите YES, чтобы отформатировать флешку.\nЛюбой другой ответ оставит её как есть."
  S_FAIL="Установка не удалась (код %s).\n\nСамая частая причина: соединение с интернетом прервалось\nво время скачивания. Диск уже стёрт; начать заново\nбезопасно.\n\nПодробности:\n%s\n\nПолный журнал: %s"
  S_VFY_ASK="Проверить, что диск записан правильно?\n\nОбратное чтение %s с %s.\nЗанимает от 1 до 3 минут в зависимости от диска.\n\nРекомендуется, особенно для старого диска."
  S_VFY_RUN="Обратное чтение и проверка диска..."
  S_VFY_OK="Проверка пройдена.\n\nСодержимое диска точно совпадает с образом.\n\nSHA256: %s..."
  S_VFY_KO="ПРОВЕРКА НЕ ПРОЙДЕНА\n\nДиск не совпадает с записанным образом:\n  ожидалось: %s...\n  прочитано: %s...\n\nВероятные причины: сбойный диск, кабель SATA, память.\nНЕ используйте эту установку: повторите попытку, а если\nошибка повторится, замените диск."
  S_VFY_SKIP="Контрольная сумма образа не вычислена: проверка\nневозможна.\nУстановка почти наверняка в порядке (скачивание\nпроверяется самим сжатым форматом)."
  S_LOG_ASK="Скопировать журнал установки на флешку USB?\n\nИначе он пропадёт при перезагрузке. Именно этот файл\nнужно приложить, сообщая о проблеме."
  S_LOG_OK="Журнал скопирован на %s\n(файл haos-install-*.log)\n\nФлешку можно извлечь."
  S_LOG_MENU="Куда сохранить журнал установки?\n\nАвтоматически не найден носитель для записи.\nВыберите вариант:"
  S_LOG_M_USB="Подключить флешку USB"
  S_LOG_M_USB_D="подождите 5 с и подтвердите"
  S_LOG_M_FMT="Отформатировать эту флешку"
  S_LOG_M_FMT_D="стирает установщик"
  S_LOG_M_SHOW="Показать на экране"
  S_LOG_M_SHOW_D="чтобы сфотографировать"
  S_LOG_M_NONE="Не сохранять"
  S_LOG_M_NONE_D="журнал будет потерян"
  S_LOG_VTOY="Флешка распознана, но занята системой загрузки, и\nосвободить её автоматически не удалось.\n\nТак бывает с Ventoy: образ установки — это файл на этой\nфлешке.\n\n-> ОТКЛЮЧИТЕ и снова ПОДКЛЮЧИТЕ флешку, подождите 5\n   секунд и выберите ниже «Подключить флешку USB».\n\nУстановщик работает из памяти: отключать флешку безопасно."
  S_LOG_RO="Носитель найден, но он только для чтения.\n\nТак бывает с Ventoy: система установки использует этот\nраздел, поэтому изменить его нельзя.\n\nОтключение и повторное подключение флешки освободит её,\nлибо выберите другой вариант."
  S_LOG_DETECT="Поиск носителей..."
  S_LOG_RETRY="Записываемого носителя по-прежнему нет.\n\nВозможно, флешка не размечена или её формат не\nраспознаётся. Можно попробовать другую."
  S_LOG_FULL="Носитель найден, но он заполнен.\n\nНе хватает места для журнала. Подключите другую флешку\nUSB или покажите журнал на экране на следующем шаге,\nчтобы сфотографировать его."
  S_LOG_NONE="Журнал не скопирован.\n\nЕго всё ещё можно прочитать из оболочки:\n  cat %s"
  S_WIFI_PUSH="Сеть Wi-Fi \"%s\" настроена заранее.\n\nHome Assistant попытается подключиться при первом запуске,\nНО только если ваш адаптер Wi-Fi входит в список\nподдерживаемых (он короче списка этого установщика).\n\nЕсли через 5 минут Home Assistant не в сети:\n - подключите кабель Ethernet (рекомендуется), либо\n - сообщите о своём адаптере проекту Home Assistant OS.\n\nДержите компьютер в зоне действия Wi-Fi."
  S_WIFI_PUSH_FAIL="Не удалось заранее настроить Wi-Fi в образе.\n\nHome Assistant загрузится без сети: подключить её нужно\nбудет позже (кабель Ethernet либо клавиатура и экран на\nконсоли HAOS)."
  S_WIFI_PUSH_SKIP="Эту сеть Wi-Fi нельзя настроить заранее.\n\nОна опирается на сертификаты или режим, который Home\nAssistant не может принять как есть. Ничего не записано:\nлучше так, чем сеть, которая никогда не поднимется.\n\nЧТО СДЕЛАТЬ ПОСЛЕ УСТАНОВКИ:\n - подключите кабель Ethernet (проще всего), либо\n - настройте Wi-Fi из консоли Home Assistant\n   (клавиатура и экран на компьютере).\n\nПодробности в журнале установки."
  S_DONE_LOG="\n\nФлешка отформатирована: это снова обычная флешка USB, и\nжурнал установки записан на неё."
  S_FMT_ASK="Отформатировать флешку установщика?\n\n%s\n\nОна снова станет обычной флешкой FAT32, пригодной\nгде угодно, и журнал установки будет записан на неё.\n\n⚠  УСТАНОВЩИК БУДЕТ СТЁРТ: чтобы установить заново,\nпридётся записать флешку с другого компьютера.\n\nУстановка Home Assistant, уже записанная на диск, не\nзатрагивается."
  S_FMT_FAIL="Не удалось отформатировать флешку.\n\nНичего не тронуто: она по-прежнему годится как\nустановщик. Подробности в журнале."
  S_FMT_BROKEN="Форматирование флешки прервалось на середине.\n\n⚠  Флешка больше не загрузочная: придётся записать её\nзаново, чтобы снова использовать как установщик.\n\nУстановка Home Assistant на диске не затронута, она\nзавершена."
  S_DONE="Установка завершена.\n\nHome Assistant OS установлен на %s.\n\n-> ИЗВЛЕКИТЕ ФЛЕШКУ USB СЕЙЧАС, до подтверждения.\n   (установщик работает из памяти: она больше не нужна)\n\nДАЛЬШЕ:\n 1. Подтвердите ниже: компьютер загрузится в Home Assistant.\n 2. Оставьте сетевой кабель подключённым.\n 3. Подождите от 2 до 5 минут (первая загрузка).\n 4. С другого устройства:  http://homeassistant.local"
  S_UNAT_ACTIVE="Автоустановка.\n\nФайл настроек: %s\nЯзык: %s\n\nВопросов не будет."
  S_UNAT_NOWIPE="Автоустановка отклонена.\n\nВ файле нет WIPE=yes:\n%s\n\nНичего не изменено."
  S_UNAT_NODISK="Автоустановка отклонена.\n\nDISK=%s здесь не подходящий диск.\n\nНичего не изменено."
  S_UNAT_MULTI="Автоустановка отклонена.\n\nНайдено %s подходящих дисков:\n%s\n\nУкажите DISK= для одного из них в файле\nнастроек. Ничего не изменено."
  S_UNAT_NONET="Автоустановка не удалась.\n\nНет сети и нет образа на флешке:\nскачать нечего.\n\nНичего не изменено."
  S_UNAT_NOSTAGE="Автоустановка отклонена.\n\nМало свободной памяти для образа (%s) и нет\nзаписываемого носителя, чтобы его сохранить.\n\nДобавьте STREAM=yes, чтобы разрешить стирание\nдиска до проверки загрузки.\nНичего не записано."
  S_UNAT_OFF_REBOOT="Установка завершена.\n\nHome Assistant OS установлен на %s.\n\nВыньте USB-флешку сейчас.\nКомпьютер перезагрузится через 15 секунд."
  S_UNAT_OFF_HALT="Установка завершена.\n\nHome Assistant OS установлен на %s.\n\nВыньте USB-флешку сейчас.\nКомпьютер выключится через 15 секунд."
  S_UNAT_FAIL="\n\nЖурнал показан здесь и сохранён в\n%s.\n\nКомпьютер выключится через 20 секунд."
;;
cs)
  S_STAGE_ASK="Nedostatek volné paměti pro uložení obrazu do RAM (%s).\nNebylo nalezeno zapisovatelné médium s tolika volného místa.\nPřipojte USB disk nebo externí disk a zvolte Zkusit znovu: obraz se tam stáhne a ověří, NEŽ se cokoli smaže.\n\"Zápis v jednom průchodu\" naopak nejprve smaže cílový disk: pokud potom vypadne síť, zůstane prázdný disk."
  S_STAGE_INFO="Nedostatek paměti pro umístění obrazu do RAM.\nStahuje se do:\n%s\nNa cílový disk se nic nezapisuje, dokud není soubor kompletní a ověřený; potom se odtud smaže."
  S_STAGE_RETRY="Zkusit znovu"
  S_STAGE_STREAM="Zapis v jednom pruchodu"
  S_TITLE="Instalace Home Assistant OS"
  S_WARN="⚠  UPOZORNĚNÍ — instalace Home Assistant OS"
  S_RESCUE="\n\nBudete moci uložit protokol a potom počítač vypnout."
  S_HALT_ASK="Co teď?\n\nUž se nic nezmění: instalace skončila neúspěchem.\nVypnutí je obvyklá volba.\n\nTerminál má smysl jen tehdy, když se v něm vyznáte."
  S_HALT_OFF="Vypnout počítač"
  S_HALT_SHELL="Otevřít terminál"
  S_CANCELLED="Instalace zrušena."
  S_VFY_ABORT="Disk neodpovídá obrazu: nestartujte z něj."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="ZKONTROLUJTE (zjištěn režim Legacy/CSM)"
  S_SB_OFF="OK (vypnuto)"
  S_SB_ON="ZKONTROLUJTE (zapnuto — HAOS nenaběhne)"
  S_SB_UNK="ZKONTROLUJTE (stav neznámý)"
  S_WELCOME="Vítejte.\n\nTento nástroj nainstaluje nejnovější Home Assistant OS\nna tento počítač, bez příkazové řádky.\n\nKONTROLA POŽADAVKŮ:\n  Režim spouštění : %s\n  Secure Boot     : %s\n\n„ZKONTROLUJTE“ znamená, že Home Assistant po instalaci\nnemusí naběhnout. Opravte to v BIOSu (Del/F2 při zapnutí).\nNic není zablokováno: můžete pokračovat.\n\nU kroku s diskem bude CELÝ vybraný disk smazán."
  S_NET_ETH="Hledání kabelového připojení (Ethernet)..."
  S_SRC_ASK="Odkud má image pocházet?\n\nStahování vyžaduje připojení k internetu.\nImage na USB disku síť nepotřebuje."
  S_SRC_DL="Stáhnout nejnovější verzi"
  S_SRC_USE="Použít image na USB disku"
  S_IMG_SCAN="Hledám image Home Assistant OS na\npřipojených USB discích..."
  S_IMG_NONE="Nebyl nalezen žádný použitelný image.\n\nSoubor se musí jmenovat\n  haos_generic-x86-64-<version>.img.xz\n\nNalezené soubory, zde nepoužitelné:\n%s\n\nPřipojte USB disk se správným image, nebo se\nvrátte a stáhněte jej."
  S_IMG_PICK="Který image zapsat na disk?"
  S_IMG_CHECK="Kontrola kontrolních součtů .xz image..."
  S_IMG_BAD="Tento image nelze ověřit:\n%s\n\n%s\n\nJe poškozený, neúplný, nebo to není skutečný\nsoubor .img.xz. Na žádný disk nebylo nic\nzapsáno."
  S_LAN_ASK="Žádné síťové připojení.\n\nPřipojte k počítači kabel Ethernet (LAN) a zvolte\nZkusit znovu.\n\nBez sítě nelze obraz stáhnout.\nNa žádný disk zatím nebylo nic zapsáno."
  S_LAN_RETRY="Zkusit znovu"
  S_LAN_WIFI="Použít Wi-Fi"
  S_NET_NOWIFI="Nebyl nalezen použitelný adaptér Wi-Fi.\n\n%s\n\nPřipojte kabel Ethernet nebo použijte ruční nastavení\nna další obrazovce."
  S_NET_SCAN="Hledání sítí Wi-Fi..."
  S_NET_PICK="Vyberte síť Wi-Fi:"
  S_NET_RESCAN="[ Hledat znovu ]"
  S_NET_RESCAN_D="síť není? zkuste znovu"
  S_NET_MANUAL="[ Ruční nastavení ]"
  S_NET_MANUAL_D="skryté SSID, WPA enterprise, statická IP (nmtui)"
  S_NET_ETHRETRY="[ Zkusit Ethernet znovu ]"
  S_NET_ETHRETRY_D="kabel mezitím připojen"
  S_NET_QUIT="Ukončit instalátor?\n\nNení nastavena žádná síť: bez přístupu k internetu\ninstalace nemůže pokračovat."
  S_NET_PSK="Heslo sítě \"%s\":\n(zobrazeno kvůli vyhnutí se překlepům)"
  S_NET_CONN="Připojování k \"%s\"..."
  S_NET_FAIL="Připojení k \"%s\" se nezdařilo.\n\n%s\n\nZkontrolujte heslo nebo použijte ruční nastavení."
  S_VER_FETCH="Zjišťování nejnovější verze Home Assistant OS..."
  S_VER_FAIL="Verzi Home Assistant OS nelze určit.\n\nOba zdroje byly vyzkoušeny bez úspěchu:\n  version.home-assistant.io  (kanál stable)\n  api.github.com             (poslední vydání)\n\nInstalace nemůže pokračovat: bez verze není obraz\nke stažení.\n\nZkontrolujte přístup k internetu a DNS a spusťte\ninstalátor znovu."
  S_VER_NOIMG="Pro verzi %s nebyl nalezen obraz:\n%s"
  S_DISK_NONE="Nebyl nalezen žádný interní disk."
  S_DISK_PICK="Na který disk nainstalovat Home Assistant OS?\nVEŠKERÝ obsah bude trvale smazán.\n\nDisky označené [!! USB / EXTERNÍ !!] jsou přenosné:\npravděpodobně záložní disk, ne váš cíl."
  S_DISK_SMALL="Disk %s má %s GB.\n\nHome Assistant potřebuje alespoň 32 GB. Zápis může selhat\nnebo nechat příliš málo místa.\n\nZatím nebylo nic smazáno."
  S_DISK_CONFIRM="Disk %s bude ÚPLNĚ SMAZÁN.\n\nZjištěný současný obsah:\n%s\n\nNapište YES (velkými písmeny) pro smazání a instalaci\nHome Assistant OS.\nJakákoli jiná odpověď zde skončí, aniž by se něco smazalo."
  S_CONFIRM_T="⚠  POSLEDNÍ POTVRZENÍ"
  S_STOP="Zastavit (doporučeno)"
  S_GOON="Přesto pokračovat"
  S_STOPPED="Zastaveno před jakoukoli změnou."
  S_PREP="Příprava disku %s..."
  S_WRITING="Stahování HAOS %s.\nNevypínejte počítač."
  S_WRITE_HEAD="Zápis obrazu na %s.\nNevypínejte počítač."
  S_DL_CHECK="Kontrola staženého obrazu..."
  S_DL_RESUME="Pokračování stahování: %s z %s už je na disku."
  S_DL_RETRY="Stahování se zastavilo (kód curl %s).\n\nPoslední řádky protokolu:\n%s\n\nPokračovat tam, kde skončilo?"
  S_DL_ABORT="Stahování nebylo dokončeno.\n\nNIC NEBYLO ZAPSÁNO: disk je přesně v původním stavu\na jeho obsah je stále na místě.\n\nPodrobnosti:\n%s\n\nÚplný protokol: %s"
  S_DL_BAD="Stažený obraz je poškozený (kontrolní součty .xz\nnesouhlasí) — dvakrát za sebou.\n\nNIC NEBYLO ZAPSÁNO: disk je nedotčen.\nUkazuje to na síť nebo kešující proxy, ne na disk.\n\nPodrobnosti:\n%s\n\nÚplný protokol: %s"
  S_DISK_HA="⚠  Na tomto disku už je instalace Home Assistant\n   (nalezeny hassos-boot / hassos-data). Smazání zničí vaši\n   konfiguraci, doplňky a historii."
  S_FMT_TYPE="Napište YES pro naformátování disku.\nJakákoli jiná odpověď ho nechá tak, jak je."
  S_FAIL="Instalace selhala (kód %s).\n\nNejčastější příčina: připojení k internetu se přerušilo\nběhem stahování. Disk je už smazán; začít znovu je\nbezpečné.\n\nPodrobnosti:\n%s\n\nÚplný protokol: %s"
  S_VFY_ASK="Ověřit, že byl disk zapsán správně?\n\nČte zpět %s z %s.\nTrvá 1 až 3 minuty podle disku.\n\nDoporučeno, zvláště u staršího disku."
  S_VFY_RUN="Čtení zpět a ověřování disku..."
  S_VFY_OK="Ověření prošlo.\n\nObsah disku přesně odpovídá obrazu.\n\nSHA256: %s..."
  S_VFY_KO="OVĚŘENÍ SELHALO\n\nDisk neodpovídá zapsanému obrazu:\n  očekáváno: %s...\n  přečteno : %s...\n\nPravděpodobné příčiny: vadný disk, kabel SATA, paměť.\nNEPOUŽÍVEJTE tuto instalaci: zkuste to znovu, a pokud chyba\npřetrvá, vyměňte disk."
  S_VFY_SKIP="Kontrolní součet obrazu nebyl vypočten: ověření není\nmožné.\nInstalace je téměř jistě v pořádku (stažení ověřuje sám\nkomprimovaný formát)."
  S_LOG_ASK="Zkopírovat protokol instalace na USB disk?\n\nJinak se při restartu ztratí. Je to soubor, který je\ntřeba přiložit při hlášení problému."
  S_LOG_OK="Protokol zkopírován na %s\n(soubor haos-install-*.log)\n\nDisk můžete vyjmout."
  S_LOG_MENU="Kam uložit protokol instalace?\n\nNebylo automaticky nalezeno žádné zapisovatelné médium.\nZvolte možnost:"
  S_LOG_M_USB="Připojit USB disk"
  S_LOG_M_USB_D="počkejte 5 s a potvrďte"
  S_LOG_M_FMT="Naformátovat tento disk"
  S_LOG_M_FMT_D="smaže instalátor"
  S_LOG_M_SHOW="Zobrazit na obrazovce"
  S_LOG_M_SHOW_D="abyste ho vyfotili"
  S_LOG_M_NONE="Neukládat"
  S_LOG_M_NONE_D="protokol se ztratí"
  S_LOG_VTOY="Disk je rozpoznán, ale je rezervován systémem spouštění\na nepodařilo se ho automaticky uvolnit.\n\nDěje se to u Ventoy: instalační obraz je soubor na tomto\ndisku.\n\n-> ODPOJTE a znovu PŘIPOJTE disk, počkejte 5 sekund\na vyberte níže „Připojit USB disk“.\n\nInstalátor běží z paměti: odpojení je neškodné."
  S_LOG_RO="Bylo nalezeno médium, ale je pouze pro čtení.\n\nDěje se to u Ventoy: instalační systém tento oddíl používá,\ntakže ho nelze změnit.\n\nOdpojení a opětovné připojení disku ho uvolní, nebo zvolte\njinou možnost."
  S_LOG_DETECT="Zjišťování médií..."
  S_LOG_RETRY="Stále není kam zapisovat.\n\nDisk nemusí mít oddíly nebo jeho formát není rozpoznán.\nMůžete zkusit jiný."
  S_LOG_FULL="Bylo nalezeno médium, ale je plné.\n\nNení místo pro protokol. Připojte jiný USB disk, nebo\nv dalším kroku zobrazte protokol na obrazovce a vyfoťte ho."
  S_LOG_NONE="Protokol nebyl zkopírován.\n\nStále ho lze přečíst z shellu:\n  cat %s"
  S_WIFI_PUSH="Síť Wi-Fi \"%s\" je přednastavena.\n\nHome Assistant se při prvním spuštění pokusí připojit —\nALE jen pokud je vaše karta Wi-Fi mezi podporovanými\n(jejich seznam je kratší než seznam tohoto instalátoru).\n\nPokud Home Assistant není po 5 min online:\n - připojte kabel Ethernet (doporučeno), nebo\n - nahlaste svou kartu projektu Home Assistant OS.\n\nUdržujte počítač v dosahu Wi-Fi."
  S_WIFI_PUSH_FAIL="Wi-Fi se nepodařilo přednastavit do obrazu.\n\nHome Assistant naběhne bez sítě: budete ji muset připojit\npozději (kabel Ethernet, nebo klávesnice a obrazovka na\nkonzoli HAOS)."
  S_WIFI_PUSH_SKIP="Tuto síť Wi-Fi nelze přednastavit.\n\nSpoléhá na certifikáty nebo režim, který Home Assistant\nnemůže převzít tak, jak je. Nic nebylo zapsáno: lepší než\nsíť, která nikdy nenaběhne.\n\nCO UDĚLAT PO INSTALACI:\n - připojte kabel Ethernet (nejjednodušší), nebo\n - nastavte Wi-Fi z konzole Home Assistant\n   (klávesnice a obrazovka na počítači).\n\nPodrobnosti jsou v protokolu instalace."
  S_DONE_LOG="\n\nDisk byl naformátován: je z něj opět běžný USB disk\na protokol instalace je na něm uložen."
  S_FMT_ASK="Naformátovat instalační USB disk?\n\n%s\n\nBude z něj opět běžný disk FAT32, použitelný všude,\na protokol instalace se na něj zkopíruje.\n\n⚠  INSTALÁTOR BUDE SMAZÁN: pro novou instalaci bude třeba\ndisk znovu zapsat z jiného počítače.\n\nInstalace Home Assistant už zapsaná na disku není\ndotčena."
  S_FMT_FAIL="Disk se nepodařilo naformátovat.\n\nNic nebylo dotčeno: stále ho lze použít jako instalátor.\nPodrobnosti jsou v protokolu."
  S_FMT_BROKEN="Formátování disku selhalo v polovině.\n\n⚠  Disk už není bootovatelný: musíte ho znovu zapsat,\nabyste ho použili jako instalátor.\n\nInstalace Home Assistant na disku není narušena, je\nkompletní."
  S_DONE="Instalace dokončena.\n\nHome Assistant OS je nainstalován na %s.\n\n-> VYJMĚTE NYNÍ USB DISK, než potvrdíte.\n   (instalátor běží z paměti: už ho nepotřebuje)\n\nDALŠÍ KROKY:\n 1. Potvrďte níže: počítač se restartuje do Home Assistant.\n 2. Nechte síťový kabel zapojený.\n 3. Počkejte 2 až 5 minut (první spuštění).\n 4. Z jiného zařízení:  http://homeassistant.local"
  S_UNAT_ACTIVE="Instalace bez obsluhy.\n\nKonfigurační soubor: %s\nJazyk: %s\n\nNebude položena žádná otázka."
  S_UNAT_NOWIPE="Instalace bez obsluhy odmítnuta.\n\nV souboru chybí WIPE=yes:\n%s\n\nNic nebylo změněno."
  S_UNAT_NODISK="Instalace bez obsluhy odmítnuta.\n\nDISK=%s zde není použitelný disk.\n\nNic nebylo změněno."
  S_UNAT_MULTI="Instalace bez obsluhy odmítnuta.\n\nNalezeno %s použitelných disků:\n%s\n\nNastav DISK= na jeden z nich v konfiguračním\nsouboru. Nic nebylo změněno."
  S_UNAT_NONET="Instalace bez obsluhy selhala.\n\nŽádná síť a žádný obraz na disku:\nnení co stáhnout.\n\nNic nebylo změněno."
  S_UNAT_NOSTAGE="Instalace bez obsluhy odmítnuta.\n\nMálo volné RAM pro obraz (%s) a žádné\nzapisovatelné médium, kam ho uložit.\n\nPřidej STREAM=yes, aby se disk smazal ještě před\nkontrolou stažení.\nNic nebylo zapsáno."
  S_UNAT_OFF_REBOOT="Instalace dokončena.\n\nHome Assistant OS je nainstalován na %s.\n\nVyndej nyní USB flash disk.\nPočítač se restartuje za 15 sekund."
  S_UNAT_OFF_HALT="Instalace dokončena.\n\nHome Assistant OS je nainstalován na %s.\n\nVyndej nyní USB flash disk.\nPočítač se vypne za 15 sekund."
  S_UNAT_FAIL="\n\nZáznam je vidět zde a je uložen v\n%s.\n\nPočítač se vypne za 20 sekund."
;;
no)
  S_STAGE_ASK="For lite ledig minne til å holde bildet i RAM (%s).\nFant ingen skrivbart medium med så mye ledig plass.\nKoble til en USB-pinne eller en ekstern disk og velg Prøv igjen: bildet lastes ned dit og kontrolleres FØR noe slettes.\n\"Skriv i én omgang\" sletter i stedet måldisken først: faller nettet ut etterpå, står du igjen med en tom disk."
  S_STAGE_INFO="For lite minne til å legge bildet i RAM.\nDet lastes ned til:\n%s\nIngenting skrives til måldisken før filen er komplett og kontrollert, og den slettes derfra etterpå."
  S_STAGE_RETRY="Prøv igjen"
  S_STAGE_STREAM="Skriv i én omgang"
  S_TITLE="Installasjon av Home Assistant OS"
  S_WARN="⚠  ADVARSEL — installasjon av Home Assistant OS"
  S_RESCUE="\n\nDu kan lagre loggen og deretter slå av PC-en."
  S_HALT_ASK="Hva nå?\n\nIngenting mer endres: installasjonen mislyktes.\nÅ slå av er det normale valget.\n\nTerminalen er bare nyttig hvis du kjenner den."
  S_HALT_OFF="Slå av PC-en"
  S_HALT_SHELL="Åpne en terminal"
  S_CANCELLED="Installasjonen ble avbrutt."
  S_VFY_ABORT="Disken stemmer ikke med bildet: ikke start fra den."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="SJEKK DETTE (Legacy/CSM-modus funnet)"
  S_SB_OFF="OK (slått av)"
  S_SB_ON="SJEKK DETTE (på — HAOS starter ikke)"
  S_SB_UNK="SJEKK DETTE (status ukjent)"
  S_WELCOME="Velkommen.\n\nDette verktøyet installerer nyeste Home Assistant OS på\ndenne PC-en, uten kommandolinje.\n\nKONTROLL AV KRAV:\n  Oppstartsmodus : %s\n  Secure Boot    : %s\n\n\"SJEKK DETTE\" betyr at Home Assistant kanskje ikke starter\netter installasjonen. Rett det i BIOS (Del/F2 ved oppstart).\nIngenting er blokkert: du kan fortsette.\n\nI disksteget slettes HELE disken du velger."
  S_NET_ETH="Ser etter kablet (Ethernet) tilkobling..."
  S_SRC_ASK="Hvor skal avbildningen komme fra?\n\nNedlasting krever internettforbindelse.\nEn avbildning pa en USB-pinne krever ikke nett."
  S_SRC_DL="Last ned nyeste versjon"
  S_SRC_USE="Bruk en avbildning pa en USB-pinne"
  S_IMG_SCAN="Ser etter Home Assistant OS-avbildninger pa\nde tilkoblede pinnene..."
  S_IMG_NONE="Fant ingen brukbar avbildning.\n\nFilen ma hete\n  haos_generic-x86-64-<version>.img.xz\n\nFiler funnet, men ubrukelige her:\n%s\n\nSett inn en pinne med riktig avbildning, eller\nga tilbake og last den ned."
  S_IMG_PICK="Hvilken avbildning skal skrives til disken?"
  S_IMG_CHECK="Sjekker .xz-kontrollsummene til avbildningen..."
  S_IMG_BAD="Denne avbildningen kunne ikke verifiseres:\n%s\n\n%s\n\nDen er skadet, ufullstendig, eller ikke en\nordentlig .img.xz-fil. Ingenting er skrevet til\nnoen disk."
  S_LAN_ASK="Ingen nettverkstilkobling.\n\nKoble en Ethernet-kabel (LAN) til PC-en, og velg\nPrøv igjen.\n\nUten nettverk kan bildet ikke lastes ned.\nIngenting er skrevet til noen disk ennå."
  S_LAN_RETRY="Prøv igjen"
  S_LAN_WIFI="Bruk Wi-Fi i stedet"
  S_NET_NOWIFI="Ingen brukbar Wi-Fi-adapter funnet.\n\n%s\n\nKoble til en Ethernet-kabel, eller bruk manuell\nkonfigurasjon på neste skjerm."
  S_NET_SCAN="Ser etter Wi-Fi-nettverk..."
  S_NET_PICK="Velg Wi-Fi-nettverket ditt:"
  S_NET_RESCAN="[ Søk igjen ]"
  S_NET_RESCAN_D="ingen nettverk? prøv igjen"
  S_NET_MANUAL="[ Manuell konfigurasjon ]"
  S_NET_MANUAL_D="skjult SSID, WPA enterprise, fast IP (nmtui)"
  S_NET_ETHRETRY="[ Prøv Ethernet igjen ]"
  S_NET_ETHRETRY_D="kabel koblet til i mellomtiden"
  S_NET_QUIT="Avslutte installasjonsprogrammet?\n\nIngen nettverk er konfigurert: installasjonen kan ikke\nfortsette uten internett."
  S_NET_PSK="Passord for nettverket \"%s\":\n(vises i klartekst for å unngå skrivefeil)"
  S_NET_CONN="Kobler til \"%s\"..."
  S_NET_FAIL="Kunne ikke koble til \"%s\".\n\n%s\n\nSjekk passordet, eller bruk manuell konfigurasjon."
  S_VER_FETCH="Slår opp nyeste versjon av Home Assistant OS..."
  S_VER_FAIL="Kunne ikke fastslå versjonen av Home Assistant OS.\n\nBegge kildene ble prøvd uten hell:\n  version.home-assistant.io  (stable-kanalen)\n  api.github.com             (nyeste utgave)\n\nInstallasjonen kan ikke fortsette: uten versjon finnes ikke\nnoe bilde å laste ned.\n\nSjekk internett og DNS, og start installasjonsprogrammet\npå nytt."
  S_VER_NOIMG="Fant ikke noe bilde for versjon %s:\n%s"
  S_DISK_NONE="Fant ingen intern disk."
  S_DISK_PICK="Hvilken disk skal Home Assistant OS installeres på?\nALT innhold slettes permanent.\n\nDisker merket [!! USB / EKSTERN !!] er flyttbare: det er\nsannsynligvis en sikkerhetskopidisk, ikke målet ditt."
  S_DISK_SMALL="Disken %s er %s GB.\n\nHome Assistant trenger minst 32 GB. Skrivingen kan\nmislykkes eller legge igjen for lite plass.\n\nIngenting er slettet ennå."
  S_DISK_CONFIRM="Disken %s blir HELT SLETTET.\n\nNåværende innhold funnet:\n%s\n\nSkriv YES (med store bokstaver) for å slette den og\ninstallere Home Assistant OS.\nEthvert annet svar stopper her, uten at noe slettes."
  S_CONFIRM_T="⚠  SISTE BEKREFTELSE"
  S_STOP="Stopp (anbefalt)"
  S_GOON="Fortsett likevel"
  S_STOPPED="Stoppet før noe ble endret."
  S_PREP="Forbereder disken %s..."
  S_WRITING="Laster ned HAOS %s.\nIkke slå av PC-en."
  S_WRITE_HEAD="Skriver bildet til %s.\nIkke slå av PC-en."
  S_DL_CHECK="Sjekker det nedlastede bildet..."
  S_DL_RESUME="Gjenopptar nedlastingen: %s av %s er allerede på disken."
  S_DL_RETRY="Nedlastingen stoppet (curl-kode %s).\n\nSiste logglinjer:\n%s\n\nFortsette der den stoppet?"
  S_DL_ABORT="Nedlastingen ble ikke fullført.\n\nINGENTING BLE SKREVET: disken er nøyaktig som før, og\ninnholdet er fortsatt der.\n\nDetalj:\n%s\n\nFull logg: %s"
  S_DL_BAD="Det nedlastede bildet er skadet (.xz-kontrollsummene\nstemmer ikke) — to ganger på rad.\n\nINGENTING BLE SKREVET: disken er urørt.\nDet peker på nettverket eller en cacheproxy, ikke disken.\n\nDetalj:\n%s\n\nFull logg: %s"
  S_DISK_HA="⚠  Denne disken inneholder allerede en Home Assistant-\n   installasjon (fant hassos-boot / hassos-data). Sletting\n   ødelegger konfigurasjonen, tilleggene og historikken din."
  S_FMT_TYPE="Skriv YES for å formatere minnepinnen.\nEthvert annet svar lar den være som den er."
  S_FAIL="Installasjonen mislyktes (kode %s).\n\nVanligste årsak: internettforbindelsen falt ut under\nnedlastingen. Disken er allerede slettet; å begynne på nytt\ner trygt.\n\nDetaljer:\n%s\n\nFull logg: %s"
  S_VFY_ASK="Kontrollere at disken ble skrevet riktig?\n\nLeser tilbake %s fra %s.\nTar 1 til 3 minutter avhengig av disken.\n\nAnbefalt, særlig på en eldre disk."
  S_VFY_RUN="Leser tilbake og kontrollerer disken..."
  S_VFY_OK="Kontrollen gikk gjennom.\n\nDiskens innhold stemmer nøyaktig med bildet.\n\nSHA256: %s..."
  S_VFY_KO="KONTROLLEN MISLYKTES\n\nDisken stemmer ikke med bildet som ble skrevet:\n  forventet: %s...\n  lest     : %s...\n\nSannsynlige årsaker: defekt disk, SATA-kabel, minne.\nIKKE bruk denne installasjonen: prøv igjen, og bytt disk om\nfeilen vedvarer."
  S_VFY_SKIP="Bildets kontrollsum ble ikke beregnet: kan ikke\nkontrollere.\nInstallasjonen er nesten helt sikkert i orden (nedlastingen\nvalideres av det komprimerte formatet selv)."
  S_LOG_ASK="Kopiere installasjonsloggen til en USB-pinne?\n\nEllers forsvinner den ved omstart. Det er filen som skal\nvedlegges når du rapporterer problemet."
  S_LOG_OK="Loggen ble kopiert til %s\n(filen haos-install-*.log)\n\nDu kan ta ut pinnen."
  S_LOG_MENU="Hvor skal installasjonsloggen lagres?\n\nIngen skrivbart medium ble funnet automatisk.\nVelg et alternativ:"
  S_LOG_M_USB="Koble til en USB-pinne"
  S_LOG_M_USB_D="vent 5 s, og bekreft"
  S_LOG_M_FMT="Formater denne pinnen"
  S_LOG_M_FMT_D="sletter installasjonsprogrammet"
  S_LOG_M_SHOW="Vis på skjermen"
  S_LOG_M_SHOW_D="for å fotografere den"
  S_LOG_M_NONE="Ikke lagre"
  S_LOG_M_NONE_D="loggen går tapt"
  S_LOG_VTOY="Pinnen gjenkjennes, men er reservert av oppstartssystemet\nog kunne ikke frigis automatisk.\n\nDette skjer med Ventoy: installasjonsbildet er en fil på\ndenne pinnen.\n\n-> KOBLE FRA og deretter TIL pinnen igjen, vent 5 sekunder\nog velg \"Koble til en USB-pinne\" nedenfor.\n\nInstallasjonsprogrammet kjører fra minnet: å koble fra er\nufarlig."
  S_LOG_RO="Fant et medium, men det er skrivebeskyttet.\n\nDette skjer med Ventoy: installasjonssystemet bruker den\npartisjonen, så den kan ikke endres.\n\nÅ koble fra og til pinnen igjen frigjør den, eller velg et\nannet alternativ."
  S_LOG_DETECT="Ser etter medier..."
  S_LOG_RETRY="Fortsatt ingenting skrivbart.\n\nPinnen har kanskje ingen partisjoner, eller formatet\nkjennes ikke igjen. Du kan prøve en annen."
  S_LOG_FULL="Fant et medium, men det er fullt.\n\nDet er ikke plass til loggen. Koble til en annen\nUSB-pinne, eller vis loggen på skjermen i neste steg for\nå fotografere den."
  S_LOG_NONE="Loggen ble ikke kopiert.\n\nDen kan fortsatt leses fra skallet:\n  cat %s"
  S_WIFI_PUSH="Wi-Fi-nettverket \"%s\" er forhåndskonfigurert.\n\nHome Assistant prøver å koble til ved første oppstart — MEN\nbare hvis Wi-Fi-kortet ditt er blant dem det støtter (den\nlisten er kortere enn denne installatørens).\n\nHvis Home Assistant ikke er på nett etter 5 min:\n - koble til en Ethernet-kabel (anbefalt), eller\n - rapporter kortet ditt til Home Assistant OS-prosjektet.\n\nHold PC-en innenfor Wi-Fi-rekkevidde."
  S_WIFI_PUSH_FAIL="Wi-Fi kunne ikke forhåndskonfigureres i bildet.\n\nHome Assistant starter uten nettverk: du må koble det til\netterpå (Ethernet-kabel, eller tastatur og skjerm på\nHAOS-konsollen)."
  S_WIFI_PUSH_SKIP="Dette Wi-Fi-nettverket kan ikke forhåndskonfigureres.\n\nDet bygger på sertifikater eller en modus Home Assistant\nikke kan overta som det er. Ingenting ble skrevet: bedre det\nenn et nettverk som aldri kommer opp.\n\nGJØR ETTER INSTALLASJONEN:\n - koble til en Ethernet-kabel (enklest), eller\n - konfigurer Wi-Fi fra Home Assistant-konsollen\n   (tastatur og skjerm på PC-en).\n\nDetaljene står i installasjonsloggen."
  S_DONE_LOG="\n\nPinnen ble formatert: den er en vanlig USB-pinne igjen, og\ninstallasjonsloggen ligger på den."
  S_FMT_ASK="Formatere installasjonspinnen?\n\n%s\n\nDen blir en vanlig FAT32-pinne igjen, brukbar overalt, og\ninstallasjonsloggen kopieres til den.\n\n⚠  INSTALLASJONSPROGRAMMET SLETTES: for å installere på nytt\nmå pinnen skrives på nytt fra en annen datamaskin.\n\nHome Assistant-installasjonen som allerede er skrevet til\ndisken, påvirkes ikke."
  S_FMT_FAIL="Pinnen kunne ikke formateres.\n\nIngenting ble rørt: den kan fortsatt brukes som\ninstallasjonsprogram. Detaljene står i loggen."
  S_FMT_BROKEN="Formateringen av pinnen mislyktes halvveis.\n\n⚠  Pinnen kan ikke lenger starte fra: du må skrive den på\nnytt for å bruke den som installasjonsprogram.\n\nHome Assistant-installasjonen på disken er ikke påvirket,\nden er komplett."
  S_DONE="Installasjonen er fullført.\n\nHome Assistant OS er installert på %s.\n\n-> TA UT USB-PINNEN NÅ, før du bekrefter.\n   (programmet kjører fra minnet: den trengs ikke lenger)\n\nNESTE:\n 1. Bekreft nedenfor: PC-en starter på nytt i Home Assistant.\n 2. La nettverkskabelen stå i.\n 3. Vent 2 til 5 minutter (første oppstart).\n 4. Fra en annen enhet:  http://homeassistant.local"
  S_UNAT_ACTIVE="Ubetjent installasjon.\n\nKonfigurasjonsfil: %s\nSpråk: %s\n\nIngen spørsmål blir stilt."
  S_UNAT_NOWIPE="Ubetjent installasjon avvist.\n\nWIPE=yes mangler i:\n%s\n\nIngenting er endret."
  S_UNAT_NODISK="Ubetjent installasjon avvist.\n\nDISK=%s er ikke en brukbar disk her.\n\nIngenting er endret."
  S_UNAT_MULTI="Ubetjent installasjon avvist.\n\nFant %s brukbare disker:\n%s\n\nSett DISK= til en av dem i konfigurasjonsfilen.\nIngenting er endret."
  S_UNAT_NONET="Ubetjent installasjon mislyktes.\n\nIngen nettverk og ingen image-fil på en penn:\ndet kan ikke lastes ned noe.\n\nIngenting er endret."
  S_UNAT_NOSTAGE="Ubetjent installasjon avvist.\n\nFor lite ledig RAM til image-filen (%s), og ingen\nskrivbart medium å legge den på.\n\nLegg til STREAM=yes for å godta at disken slettes\nfør nedlastingen er kontrollert.\nIngenting er skrevet."
  S_UNAT_OFF_REBOOT="Installasjonen er ferdig.\n\nHome Assistant OS er installert på %s.\n\nTa ut USB-pennen nå.\nPC-en starter på nytt om 15 sekunder."
  S_UNAT_OFF_HALT="Installasjonen er ferdig.\n\nHome Assistant OS er installert på %s.\n\nTa ut USB-pennen nå.\nPC-en slår seg av om 15 sekunder."
  S_UNAT_FAIL="\n\nLoggen vises her og lagres i\n%s.\n\nPC-en slår seg av om 20 sekunder."
;;
fi)
  S_STAGE_ASK="Liian vähän vapaata muistia kuvan pitämiseksi RAMissa (%s).\nKirjoitettavaa mediaa, jossa on niin paljon vapaata tilaa, ei löytynyt.\nKytke USB-muistitikku tai ulkoinen levy ja valitse Yritä uudelleen: kuva ladataan sinne ja tarkistetaan ENNEN kuin mitään poistetaan.\n\"Kirjoita yhdellä kertaa\" poistaa sen sijaan kohdelevyn ensin: jos verkko katkeaa sen jälkeen, jäljelle jää tyhjä levy."
  S_STAGE_INFO="Liian vähän muistia kuvan sijoittamiseksi RAMiin.\nSe ladataan kohteeseen:\n%s\nKohdelevylle ei kirjoiteta mitään ennen kuin tiedosto on valmis ja tarkistettu, ja se poistetaan siltä kirjoituksen jälkeen."
  S_STAGE_RETRY="Yritä uudelleen"
  S_STAGE_STREAM="Kirjoita yhdellä kertaa"
  S_TITLE="Home Assistant OS -asennus"
  S_WARN="⚠  VAROITUS — Home Assistant OS -asennus"
  S_RESCUE="\n\nVoit tallentaa lokin ja sammuttaa sitten tietokoneen."
  S_HALT_ASK="Mitä nyt?\n\nMikään ei enää muutu: asennus epäonnistui.\nSammuttaminen on tavallinen valinta.\n\nPäätteestä on hyötyä vain, jos osaat käyttää sitä."
  S_HALT_OFF="Sammuta tietokone"
  S_HALT_SHELL="Avaa pääte"
  S_CANCELLED="Asennus peruutettu."
  S_VFY_ABORT="Levy ei vastaa imagen sisältöä: älä käynnistä siltä."
  S_OK_UEFI="OK (UEFI)"
  S_BAD_UEFI="TARKISTA TÄMÄ (Legacy/CSM-tila havaittu)"
  S_SB_OFF="OK (pois päältä)"
  S_SB_ON="TARKISTA TÄMÄ (päällä — HAOS ei käynnisty)"
  S_SB_UNK="TARKISTA TÄMÄ (tila tuntematon)"
  S_WELCOME="Tervetuloa.\n\nTämä työkalu asentaa uusimman Home Assistant OS:n tälle\ntietokoneelle ilman komentoriviä.\n\nVAATIMUSTEN TARKISTUS:\n  Käynnistystila : %s\n  Secure Boot    : %s\n\n\"TARKISTA TÄMÄ\" tarkoittaa, että Home Assistant ei\nvälttämättä käynnisty asennuksen jälkeen. Korjaa BIOSissa\n(Del/F2 käynnistyksen yhteydessä). Mikään ei ole estetty:\nvoit jatkaa.\n\nLevyvaiheessa KOKO valittu levy tyhjennetään."
  S_NET_ETH="Etsitään kaapeliyhteyttä (Ethernet)..."
  S_SRC_ASK="Mistä levykuva tulee?\n\nLataus vaatii verkkoyhteyden. USB-muistilla\noleva levykuva ei vaadi verkkoa lainkaan."
  S_SRC_DL="Lataa uusin versio"
  S_SRC_USE="Käytä USB-muistilla olevaa levykuvaa"
  S_IMG_SCAN="Etsin Home Assistant OS -levykuvia\nliitetyiltä muisteilta..."
  S_IMG_NONE="Sopivaa levykuvaa ei löytynyt.\n\nTiedoston nimi pitää olla\n  haos_generic-x86-64-<version>.img.xz\n\nLöytyneet tiedostot, jotka eivät käy tässä:\n%s\n\nLiitä muisti, jossa on oikea levykuva, tai palaa\ntakaisin ja lataa se."
  S_IMG_PICK="Mikä levykuva kirjoitetaan levylle?"
  S_IMG_CHECK="Tarkistetaan levykuvan .xz-tarkistussummat..."
  S_IMG_BAD="Tätä levykuvaa ei voitu tarkistaa:\n%s\n\n%s\n\nSe on vioittunut, puutteellinen tai ei oikea\n.img.xz-tiedosto. Mitään ei ole kirjoitettu\nyhdellekään levylle."
  S_LAN_ASK="Ei verkkoyhteyttä.\n\nKytke Ethernet-kaapeli (LAN) tietokoneeseen ja valitse\nYritä uudelleen.\n\nIlman verkkoa imagoa ei voi ladata.\nMitään ei ole vielä kirjoitettu millekään levylle."
  S_LAN_RETRY="Yritä uudelleen"
  S_LAN_WIFI="Käytä Wi-Fiä"
  S_NET_NOWIFI="Yhtään käyttökelpoista Wi-Fi-sovitinta ei löytynyt.\n\n%s\n\nKytke Ethernet-kaapeli tai käytä manuaalista määritystä\nseuraavalla näytöllä."
  S_NET_SCAN="Etsitään Wi-Fi-verkkoja..."
  S_NET_PICK="Valitse Wi-Fi-verkko:"
  S_NET_RESCAN="[ Hae uudelleen ]"
  S_NET_RESCAN_D="verkko ei näy? yritä uudelleen"
  S_NET_MANUAL="[ Manuaalinen määritys ]"
  S_NET_MANUAL_D="piilotettu SSID, WPA enterprise, kiinteä IP (nmtui)"
  S_NET_ETHRETRY="[ Yritä Ethernetiä uudelleen ]"
  S_NET_ETHRETRY_D="kaapeli kytketty sillä välin"
  S_NET_QUIT="Poistutaanko asentajasta?\n\nVerkkoa ei ole määritetty: asennus ei voi jatkua ilman\ninternetyhteyttä."
  S_NET_PSK="Verkon \"%s\" salasana:\n(näytetään selvästi kirjoitusvirheiden välttämiseksi)"
  S_NET_CONN="Yhdistetään verkkoon \"%s\"..."
  S_NET_FAIL="Yhteyden muodostus verkkoon \"%s\" epäonnistui.\n\n%s\n\nTarkista salasana tai käytä manuaalista määritystä."
  S_VER_FETCH="Haetaan uusinta Home Assistant OS -versiota..."
  S_VER_FAIL="Home Assistant OS -versiota ei voitu selvittää.\n\nMolempia lähteitä yritettiin tuloksetta:\n  version.home-assistant.io  (stable-kanava)\n  api.github.com             (uusin julkaisu)\n\nAsennus ei voi jatkua: ilman versiota ei ole imagoa\nladattavaksi.\n\nTarkista internetyhteys ja DNS ja käynnistä asentaja\nuudelleen."
  S_VER_NOIMG="Versiolle %s ei löytynyt imagoa:\n%s"
  S_DISK_NONE="Sisäistä levyä ei löytynyt."
  S_DISK_PICK="Mille levylle Home Assistant OS asennetaan?\nKAIKKI sen sisältö poistetaan pysyvästi.\n\nMerkinnällä [!! USB / ULKOINEN !!] olevat levyt ovat\nirrotettavia: se on todennäköisesti varmuuskopiolevy,\nei kohteesi."
  S_DISK_SMALL="Levy %s on %s GB.\n\nHome Assistant tarvitsee vähintään 32 GB. Kirjoitus voi\nepäonnistua tai jättää liian vähän tilaa.\n\nMitään ei ole vielä poistettu."
  S_DISK_CONFIRM="Levy %s tyhjennetään KOKONAAN.\n\nNykyinen sisältö havaittu:\n%s\n\nKirjoita YES (isoilla kirjaimilla) tyhjentääksesi sen ja\nasentaaksesi Home Assistant OS:n.\nMikä tahansa muu vastaus pysäyttää tähän, mitään ei\npoisteta."
  S_CONFIRM_T="⚠  VIIMEINEN VAHVISTUS"
  S_STOP="Pysäytä (suositus)"
  S_GOON="Jatka silti"
  S_STOPPED="Pysäytetty ennen mitään muutosta."
  S_PREP="Valmistellaan levyä %s..."
  S_WRITING="Ladataan HAOS %s.\nÄlä sammuta tietokonetta."
  S_WRITE_HEAD="Kirjoitetaan imagoa levylle %s.\nÄlä sammuta tietokonetta."
  S_DL_CHECK="Tarkistetaan ladattua imagoa..."
  S_DL_RESUME="Jatketaan latausta: %s / %s on jo levyllä."
  S_DL_RETRY="Lataus pysähtyi (curl-koodi %s).\n\nLokin viimeiset rivit:\n%s\n\nJatketaanko siitä, mihin se pysähtyi?"
  S_DL_ABORT="Lataus ei valmistunut.\n\nMITÄÄN EI KIRJOITETTU: levy on täsmälleen entisellään ja\nsen sisältö on edelleen tallessa.\n\nYksityiskohdat:\n%s\n\nKoko loki: %s"
  S_DL_BAD="Ladattu imago on vioittunut (.xz-tarkistussummat eivät\ntäsmää) — kahdesti peräkkäin.\n\nMITÄÄN EI KIRJOITETTU: levy on koskematon.\nTämä viittaa verkkoon tai välimuistiproxyyn, ei levyyn.\n\nYksityiskohdat:\n%s\n\nKoko loki: %s"
  S_DISK_HA="⚠  Tällä levyllä on jo Home Assistant -asennus\n   (löytyi hassos-boot / hassos-data). Tyhjentäminen tuhoaa\n   määritykset, lisäosat ja historian."
  S_FMT_TYPE="Kirjoita YES muotoillaksesi muistitikun.\nMikä tahansa muu vastaus jättää sen ennalleen."
  S_FAIL="Asennus epäonnistui (koodi %s).\n\nYleisin syy: internetyhteys katkesi latauksen aikana.\nLevy on jo tyhjennetty; alusta aloittaminen on turvallista.\n\nYksityiskohdat:\n%s\n\nKoko loki: %s"
  S_VFY_ASK="Tarkistetaanko, että levy kirjoitettiin oikein?\n\nLukee takaisin %s levyltä %s.\nKestää 1-3 minuuttia levystä riippuen.\n\nSuositeltavaa, erityisesti vanhalla levyllä."
  S_VFY_RUN="Luetaan takaisin ja tarkistetaan levyä..."
  S_VFY_OK="Tarkistus meni läpi.\n\nLevyn sisältö vastaa imagoa täsmälleen.\n\nSHA256: %s..."
  S_VFY_KO="TARKISTUS EPÄONNISTUI\n\nLevy ei vastaa kirjoitettua imagoa:\n  odotettu: %s...\n  luettu  : %s...\n\nTodennäköisiä syitä: viallinen levy, SATA-kaapeli, muisti.\nÄLÄ käytä tätä asennusta: yritä uudelleen ja vaihda levy,\njos virhe toistuu."
  S_VFY_SKIP="Imagon tarkistussummaa ei laskettu: tarkistus ei ole\nmahdollinen.\nAsennus on lähes varmasti kunnossa (latauksen varmentaa\nitse pakattu muoto)."
  S_LOG_ASK="Kopioidaanko asennusloki USB-muistitikulle?\n\nMuuten se katoaa uudelleenkäynnistyksessä. Tämä on se\ntiedosto, joka liitetään ongelmailmoitukseen."
  S_LOG_OK="Loki kopioitu kohteeseen %s\n(tiedosto haos-install-*.log)\n\nVoit poistaa tikun."
  S_LOG_MENU="Minne asennusloki tallennetaan?\n\nKirjoitettavaa mediaa ei löytynyt automaattisesti.\nValitse vaihtoehto:"
  S_LOG_M_USB="Kytke USB-muistitikku"
  S_LOG_M_USB_D="odota 5 s ja vahvista"
  S_LOG_M_FMT="Alusta tämä tikku"
  S_LOG_M_FMT_D="poistaa asentajan"
  S_LOG_M_SHOW="Näytä ruudulla"
  S_LOG_M_SHOW_D="valokuvattavaksi"
  S_LOG_M_NONE="Älä tallenna"
  S_LOG_M_NONE_D="loki menetetään"
  S_LOG_VTOY="Tikku tunnistetaan, mutta käynnistysjärjestelmä varaa sen,\neikä sitä voitu vapauttaa automaattisesti.\n\nNäin käy Ventoyn kanssa: asennusimago on tiedosto tällä\ntikulla.\n\n-> IRROTA ja kytke tikku UUDELLEEN, odota 5 sekuntia ja\n   valitse alta \"Kytke USB-muistitikku\".\n\nAsentaja toimii muistista: irrottaminen on vaaratonta."
  S_LOG_RO="Media löytyi, mutta se on vain luku -tilassa.\n\nNäin käy Ventoyn kanssa: asennusjärjestelmä käyttää sitä\nosiota, joten sitä ei voi muuttaa.\n\nTikun irrottaminen ja uudelleen kytkeminen vapauttaa sen,\ntai valitse toinen vaihtoehto."
  S_LOG_DETECT="Etsitään medioita..."
  S_LOG_RETRY="Edelleen ei mitään kirjoitettavaa.\n\nTikulla ei ehkä ole osioita tai sen muotoa ei tunnisteta.\nVoit kokeilla toista."
  S_LOG_FULL="Media löytyi, mutta se on täynnä.\n\nLokille ei ole tilaa. Kytke toinen USB-muistitikku tai\nnäytä loki ruudulla seuraavassa vaiheessa ja kuvaa se."
  S_LOG_NONE="Lokia ei kopioitu.\n\nSe on edelleen luettavissa komentotulkista:\n  cat %s"
  S_WIFI_PUSH="Wi-Fi-verkko \"%s\" on esimääritetty.\n\nHome Assistant yrittää yhdistää ensimmäisellä\nkäynnistyksellä — MUTTA vain jos Wi-Fi-korttisi on\ntuettujen joukossa (sen luettelo on lyhyempi kuin tämän\nasentajan).\n\nJos Home Assistant ei ole verkossa 5 minuutin jälkeen:\n - kytke Ethernet-kaapeli (suositus), tai\n - ilmoita kortistasi Home Assistant OS -projektille.\n\nPidä tietokone Wi-Fi-kantaman sisällä."
  S_WIFI_PUSH_FAIL="Wi-Fiä ei voitu esimäärittää imagoon.\n\nHome Assistant käynnistyy ilman verkkoa: sinun on\nkytkettävä se jälkeenpäin (Ethernet-kaapeli tai näppäimistö\nja näyttö HAOS-konsolissa)."
  S_WIFI_PUSH_SKIP="Tätä Wi-Fi-verkkoa ei voi esimäärittää.\n\nSe perustuu sertifikaatteihin tai tilaan, jota Home\nAssistant ei voi ottaa sellaisenaan. Mitään ei kirjoitettu:\nse on parempi kuin verkko, joka ei koskaan nouse.\n\nTEE ASENNUKSEN JÄLKEEN:\n - kytke Ethernet-kaapeli (yksinkertaisin), tai\n - määritä Wi-Fi Home Assistant -konsolista\n   (näppäimistö ja näyttö tietokoneessa).\n\nYksityiskohdat ovat asennuslokissa."
  S_DONE_LOG="\n\nTikku alustettiin: se on taas tavallinen USB-muistitikku ja\nasennusloki on tallennettu sille."
  S_FMT_ASK="Alustetaanko asennustikku?\n\n%s\n\nSiitä tulee taas tavallinen FAT32-tikku, jota voi käyttää\nmissä tahansa, ja asennusloki kopioidaan sille.\n\n⚠  ASENTAJA POISTETAAN: uudelleenasennusta varten tikku on\nkirjoitettava uudelleen toisella tietokoneella.\n\nLevylle jo kirjoitettu Home Assistant -asennus ei kärsi\ntästä."
  S_FMT_FAIL="Tikkua ei voitu alustaa.\n\nMitään ei koskettu: se toimii edelleen asentajana.\nYksityiskohdat ovat lokissa."
  S_FMT_BROKEN="Tikun alustus epäonnistui kesken.\n\n⚠  Tikku ei enää käynnisty: sinun on kirjoitettava se\nuudelleen käyttääksesi sitä asentajana.\n\nLevyn Home Assistant -asennus ei vahingoittunut, se on\nvalmis."
  S_DONE="Asennus valmis.\n\nHome Assistant OS on asennettu levylle %s.\n\n-> IRROTA USB-MUISTITIKKU NYT ennen vahvistamista.\n   (asentaja toimii muistista: tikkua ei enää tarvita)\n\nSEURAAVAKSI:\n 1. Vahvista alla: tietokone käynnistyy Home Assistantiin.\n 2. Jätä verkkokaapeli kytkettynä.\n 3. Odota 2-5 minuuttia (ensimmäinen käynnistys).\n 4. Toisesta laitteesta:  http://homeassistant.local"
  S_UNAT_ACTIVE="Valvomaton asennus.\n\nAsetustiedosto: %s\nKieli: %s\n\nMitään kysymystä ei esitetä."
  S_UNAT_NOWIPE="Valvomaton asennus hylätty.\n\nWIPE=yes puuttuu tiedostosta:\n%s\n\nMitään ei muutettu."
  S_UNAT_NODISK="Valvomaton asennus hylätty.\n\nDISK=%s ei ole käyttökelpoinen levy tässä.\n\nMitään ei muutettu."
  S_UNAT_MULTI="Valvomaton asennus hylätty.\n\nLöytyi %s käyttökelpoista levyä:\n%s\n\nAseta DISK= johonkin niistä asetustiedostossa.\nMitään ei muutettu."
  S_UNAT_NONET="Valvomaton asennus epäonnistui.\n\nEi verkkoa eikä levykuvaa tikulla:\nmitään ei voi ladata.\n\nMitään ei muutettu."
  S_UNAT_NOSTAGE="Valvomaton asennus hylätty.\n\nLiian vähän vapaata RAM-muistia levykuvalle (%s)\neikä kirjoitettavaa mediaa sen säilyttämiseen.\n\nLisää STREAM=yes, jos levy saa pyyhkiytyä ennen\nlatauksen tarkistusta.\nMitään ei kirjoitettu."
  S_UNAT_OFF_REBOOT="Asennus valmis.\n\nHome Assistant OS on asennettu levylle %s.\n\nIrrota USB-tikku nyt.\nTietokone käynnistyy uudelleen 15 sekunnissa."
  S_UNAT_OFF_HALT="Asennus valmis.\n\nHome Assistant OS on asennettu levylle %s.\n\nIrrota USB-tikku nyt.\nTietokone sammuu 15 sekunnissa."
  S_UNAT_FAIL="\n\nLoki näkyy tässä ja tallennetaan tiedostoon\n%s.\n\nTietokone sammuu 20 sekunnissa."
;;
*)
  S_STAGE_ASK="Not enough free memory to hold the image in RAM (%s).\nNo writable stick or external disk with that much free space was found.\nPlug one in and choose Retry: the image is downloaded there and checked BEFORE anything is erased.\n\"Write in one pass\" instead erases the target disk first: a network drop after that leaves an empty disk."
  S_STAGE_INFO="Not enough memory to stage the image in RAM.\nIt is being downloaded to:\n%s\nNothing is written to the target disk until the file is complete and checked, and it is deleted from there once the write is done."
  S_STAGE_RETRY="Retry"
  S_STAGE_STREAM="Write in one pass"
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
  S_SRC_ASK="Where should the image come from?\n\nDownloading needs an internet connection.\nAn image on a USB stick needs no network at all."
  S_SRC_DL="Download the latest version"
  S_SRC_USE="Use an image on a USB stick"
  S_IMG_SCAN="Looking for Home Assistant OS images on the\nconnected sticks..."
  S_IMG_NONE="No usable image found.\n\nThe file must be named\n  haos_generic-x86-64-<version>.img.xz\n\nFiles found but not usable here:\n%s\n\nPlug in a stick holding the right image, or go\nback and download it instead."
  S_IMG_PICK="Which image should be written to the disk?"
  S_IMG_CHECK="Checking the image's .xz checksums..."
  S_IMG_BAD="This image could not be verified:\n%s\n\n%s\n\nIt is damaged, incomplete, or not really an\n.img.xz file. Nothing has been written to any\ndisk."
  S_LAN_ASK="No network connection.\n\nPlug an Ethernet (LAN) cable into the PC, then choose\nRetry.\n\nNo network means the image cannot be downloaded.\nNothing has been written to any disk yet."
  S_LAN_RETRY="Retry"
  S_LAN_WIFI="Use Wi-Fi instead"
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
  S_DISK_CONFIRM="Disk %s will be COMPLETELY ERASED.\n\nCurrent contents detected:\n%s\n\nType YES (in capitals) to erase it and install\nHome Assistant OS.\nAny other answer stops here, with nothing erased."
  S_CONFIRM_T="⚠  FINAL CONFIRMATION"
  S_STOP="Stop (recommended)"
  S_GOON="Continue anyway"
  S_STOPPED="Stopped before any change."
  S_PREP="Preparing disk %s..."
  S_WRITING="Downloading HAOS %s.\nDo not power off the PC."
  S_WRITE_HEAD="Writing the image to %s.\nDo not power off the PC."
  S_DL_CHECK="Checking the downloaded image..."
  S_DL_RESUME="Resuming the download: %s of %s already on disk."
  S_DL_RETRY="The download stopped (curl code %s).\n\nLast log lines:\n%s\n\nContinue from where it stopped?"
  S_DL_ABORT="The download did not complete.\n\nNOTHING WAS WRITTEN: the disk is exactly as it was,\nand its contents are still there.\n\nDetail:\n%s\n\nFull log: %s"
  S_DL_BAD="The downloaded image is corrupt (its .xz checksums do\nnot match) -- twice in a row.\n\nNOTHING WAS WRITTEN: the disk is untouched.\nThat points at the network or a caching proxy, not\nat the disk.\n\nDetail:\n%s\n\nFull log: %s"
  S_DISK_HA="⚠  This disk already holds a Home Assistant installation\n   (hassos-boot / hassos-data found). Erasing it destroys\n   your configuration, add-ons and history."
  S_FMT_TYPE="Type YES to reformat the stick.\nAnything else leaves it exactly as it is."
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
  S_FMT_FAIL="The stick could not be reformatted.\n\nNothing was touched: it is still usable as an installer.\nDetails are in the log."
  S_FMT_BROKEN="Reformatting the stick failed partway through.\n\n⚠  The stick is no longer bootable: you will have to write it\nagain to reuse it as an installer.\n\nThe Home Assistant installation on the disk is not affected,\nit is complete."
  S_DONE="Installation complete.\n\nHome Assistant OS is installed on %s.\n\n➜ REMOVE THE USB STICK NOW, before confirming.\n  (the installer runs from memory: the stick is no longer used)\n\nNEXT:\n 1. Confirm below: the PC reboots into Home Assistant.\n 2. Keep the network cable plugged in.\n 3. Wait 2 to 5 minutes (first boot).\n 4. From another device:  http://homeassistant.local"
  S_UNAT_ACTIVE="Unattended installation.\n\nConfig file: %s\nLanguage: %s\n\nNo question will be asked."
  S_UNAT_NOWIPE="Unattended installation refused.\n\nWIPE=yes is missing from:\n%s\n\nNothing has been changed."
  S_UNAT_NODISK="Unattended installation refused.\n\nDISK=%s is not a usable disk here.\n\nNothing has been changed."
  S_UNAT_MULTI="Unattended installation refused.\n\n%s usable disks found:\n%s\n\nSet DISK= to one of them in the config file.\nNothing has been changed."
  S_UNAT_NONET="Unattended installation failed.\n\nNo network and no image on a stick:\nnothing can be downloaded.\n\nNothing has been changed."
  S_UNAT_NOSTAGE="Unattended installation refused.\n\nToo little free RAM for the image (%s), and no\nwritable medium to keep it on.\n\nAdd STREAM=yes to accept erasing the disk before\nthe download is checked. Nothing has been written."
  S_UNAT_OFF_REBOOT="Installation complete.\n\nHome Assistant OS is installed on %s.\n\nRemove the USB stick now.\nThe PC restarts in 15 seconds."
  S_UNAT_OFF_HALT="Installation complete.\n\nHome Assistant OS is installed on %s.\n\nRemove the USB stick now.\nThe PC powers off in 15 seconds."
  S_UNAT_FAIL="\n\nThe log appears here and is saved at\n%s.\n\nThe PC powers off in 20 seconds."
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
  # Unattended means nobody is at the screen. A box waiting for an OK is a box
  # that never finishes, and the verification screen is the very last place to
  # stall: the install is done, the disk is written, and the run sits there for
  # ever. The text goes to the log instead, so the stick still explains it.
  if [ -n "${UNATTENDED:-}" ]; then
    logx "screen skipped (unattended): $t"
    printf '%s\n' "$2" >> "$LOG"      # as-is: it is text, not a format
    return 0
  fi
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
  if [ -n "$UNATTENDED" ]; then
    logx "UNATTENDED: stopping: $1"
    loud_console
    # No menu and no OK button: both would hang until someone power-cycles the
    # box, and the log would never reach a stick on its own.
    try_write_log "$LOG" >/dev/null 2>&1 || true
    clear
    printf '\n%s\n' "$(printf '%s\n' "$1" | sed 's/\\n/\n/g')"
    printf '%s\n' "$(printf "$S_UNAT_FAIL" "$LOG" | sed 's/\\n/\n/g')"
    sleep 20
    halt_now
    exit 1                     # halt_now could not cut the power: do not hang
  fi
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
    nl:)     km="nl" ;;
    es:)     km="es" ;;
    it:)     km="it" ;;
    pl:)     km="pl" ;;
    pt:)     km="pt-latin1" ;;
    se:)     km="sv-latin1" ;;
    ru:)     km="ru" ;;
    cz:)     km="cz-latin2" ;;
    no:)     km="no-latin1" ;;
    fi:)     km="fi-latin1" ;;
  esac
  out="$out"$'\n'"$(loadkeys "$km" 2>&1)" && return 0

  # No more silent failure: that is what masked the previous bug.
  wt_msg "$S_TITLE" \
    "Keyboard layout could not be applied / La disposition n'a pas pu être appliquée :\n\n$(echo "$out" | cut -c1-64 | head -6)\n\nQWERTY/AZERTY may be wrong. Use the manual config if needed."
  return 1
}

# ---------------------------------------------------------------------------
choose_lang_keyboard(){
  local sel other="Keyboard layout only (another country)"
  # One row per LANGUAGE, with the layout that language is normally typed on
  # applied automatically: nobody has to match a language with a layout, and the
  # list stays short enough to read at a glance.
  # The full list of 21 pairs is still one row away, because the layout really
  # does not follow from the language: a French speaker may sit at a US keyboard,
  # English is typed on QWERTY (UK) as well, and Swiss German is not the German
  # layout. That row is the exception, not the rule.
  sel=$(whiptail --title "Language & keyboard" --menu \
    "Choose your language. Its keyboard layout is set automatically.

The last line is for a keyboard from another country." \
    22 78 15 \
    "en|us|"  "English    — QWERTY   (United States)" \
    "da|dk|"  "Dansk      — QWERTY   (Denmark)" \
    "cs|cz|"  "Cestina    — QWERTZ   (Czechia)" \
    "nl|nl|"  "Nederlands — QWERTY   (Netherlands)" \
    "fi|fi|"  "Suomi      — QWERTY   (Finland)" \
    "fr|fr|"  "French     — AZERTY   (France)" \
    "de|de|"  "Deutsch    — QWERTZ   (Germany)" \
    "it|it|"  "Italiano   — QWERTY   (Italy)" \
    "no|no|"  "Norsk      — QWERTY   (Norway)" \
    "pl|pl|"  "Polski     — QWERTY   (Poland)" \
    "pt|pt|"  "Portugues  — QWERTY   (Portugal)" \
    "ru|ru|"  "Russkiy    — YTsUKEN  (Russia)" \
    "es|es|"  "Espanol    — QWERTY   (Spain)" \
    "sv|se|"  "Svenska    — QWERTY   (Sweden)" \
    "$other"  "AZERTY / QWERTY / QWERTZ elsewhere" \
    3>&1 1>&2 2>&3) || sel="en|us|"

  if [ "$sel" = "$other" ]; then
    sel=$(whiptail --title "Language & keyboard layout" --menu \
      "Pick the exact pair" \
      22 72 15 \
      "en|us|"    "English    |  QWERTY   (United States)" \
      "en|gb|"    "English    |  QWERTY   (United Kingdom)" \
      "en|de|"    "English    |  QWERTZ   (Germany)" \
      "da|dk|"    "Dansk      |  QWERTY   (Denmark)" \
      "cs|cz|"    "Cestina    |  QWERTZ   (Czechia)" \
      "nl|nl|"    "Nederlands |  QWERTY   (Netherlands)" \
      "fi|fi|"    "Suomi      |  QWERTY   (Finland)" \
      "fr|fr|"    "French     |  AZERTY   (France)" \
      "fr|be|"    "French     |  AZERTY   (Belgium)" \
      "fr|ch|fr"  "French     |  QWERTZ   (Switzerland)" \
      "fr|ca|"    "French     |  QWERTY   (Canada)" \
      "fr|us|"    "French     |  QWERTY   (United States)" \
      "de|de|"    "Deutsch    |  QWERTZ   (Germany)" \
      "de|ch|de"  "Deutsch    |  QWERTZ   (Switzerland)" \
      "it|it|"    "Italiano   |  QWERTY   (Italy)" \
      "no|no|"    "Norsk      |  QWERTY   (Norway)" \
      "pl|pl|"    "Polski     |  QWERTY   (Poland)" \
      "pt|pt|"    "Portugues  |  QWERTY   (Portugal)" \
      "ru|ru|"    "Russkiy    |  YTsUKEN  (Russia)" \
      "es|es|"    "Espanol    |  QWERTY   (Spain)" \
      "sv|se|"    "Svenska    |  QWERTY   (Sweden)" \
      3>&1 1>&2 2>&3) || sel="en|us|"
  fi

  UI_LANG="${sel%%|*}"
  local rest="${sel#*|}"
  apply_keymap "${rest%%|*}" "${rest#*|}"
  set_strings
}

# ---------------------------------------------------------------------------
# UNATTENDED MODE -- opt-in, never a default.
#
# Nothing below runs unless the kernel command line says haos.unattended=yes, or
# a file called haos-installer.cfg sits in the root of a USB stick. Booting the
# ISO and pressing Enter still gives the wizard, and the wizard still demands the
# typed YES before it erases anything: a wiped disk is not something to infer
# from a file that might just as well be left over from another machine.
#
# The file is plain text, one KEY=value per line, '#' starts a comment, Windows
# CRLF is fine. Keys are documented in README.md. It may carry the image itself
# next to it, in which case nothing is downloaded and no network is needed.
cfg_clean(){                                   # <line> -> trimmed, CR removed
  local v="${1%$'\r'}"
  v="${v#"${v%%[![:space:]]*}"}"
  v="${v%"${v##*[![:space:]]}"}"
  printf '%s' "$v"
}

config_supported_lang(){
  case "${1:-}" in en|da|de|nl|fr|es|it|pl|sv|pt|ru|cs|no|fi) return 0 ;; esac
  return 1
}

# Default console layout for a language: the same pairs choose_lang_keyboard()
# offers, so the unattended path cannot drift away from the menu.
default_keymap(){
  case "${1:-en}" in
    en) printf 'us' ;;
    da) printf 'dk' ;;
    cs) printf 'cz' ;;
    sv) printf 'se' ;;
    *)  printf '%s' "${1:-us}" ;;
  esac
}

# One line of config. Unknown keys are logged and ignored rather than fatal: a
# typo in an optional line must not cost an installation, while a missing
# WIPE=yes does stop it (see load_config).
parse_config_line(){
  local line key val
  line=$(cfg_clean "$1")
  case "$line" in ""|\#*) return 0 ;; esac
  case "$line" in
    *=*) ;;
    *) logx "config: line without '=', ignored: $line"; return 0 ;;
  esac
  key=$(cfg_clean "${line%%=*}")
  val=$(cfg_clean "${line#*=}")
  key=${key^^}                                 # wipe=yes is WIPE=yes
  case "$val" in                               # tolerate "yes" and 'yes'
    \"*\") val=${val#\"}; val=${val%\"} ;;
    \'*\') val=${val#\'}; val=${val%\'} ;;
  esac
  case "$key" in
    UNATTENDED|WIPE|POWEROFF|STREAM|FORMAT)
      case "${val,,}" in
        yes|1|true)  printf -v "CFG_$key" '%s' "yes" ;;
        no|0|false)  printf -v "CFG_$key" '%s' "" ;;
        *) logx "config: $key=$val is neither yes nor no, ignored" ;;
      esac ;;
    DISK)     CFG_DISK="$val" ;;
    IMAGE)    CFG_IMAGE="$val" ;;
    LANG)     CFG_LANG="$val" ;;
    KEYBOARD) CFG_KEYMAP="$val" ;;
    *) logx "config: unknown key $key ignored" ;;
  esac
  return 0
}

# Reads a config file into the CFG_* variables. Its directory stays mounted:
# IMAGE= paths are relative to it, and the caller unmounts it after the write.
parse_config_file(){
  local f="$1" line
  [ -r "$f" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    parse_config_line "$line"
  done < "$f"
  return 0
}

# Whether a config file asks for anything at all. The ISO ships a template with
# every key commented out, and such a file must not end the search: a real config
# further along would never be reached.
cfg_has_keys(){
  local line
  [ -r "$1" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    line=$(cfg_clean "$line")
    case "$line" in ""|\#*) continue ;; esac
    case "$line" in *=*) return 0 ;; esac
  done < "$1"
  return 1
}

# One candidate path: a config when it asks for something, a note for the log
# when it does not (someone copied the template and forgot to uncomment it).
cfg_candidate(){
  [ -f "$1" ] || return 1
  if cfg_has_keys "$1"; then
    CFG_FILE="$1"; CFG_MNT=$(dirname "$1"); return 0
  fi
  [ -n "${CFG_EMPTY:-}" ] || CFG_EMPTY="$1"
  return 1
}

# Finds haos-installer.cfg: first in whatever is already mounted (a stick the
# live system mounted, or an ISO someone remastered with a config inside), then
# by mounting removable partitions read-only, the same candidates find_images()
# walks. Read-only on purpose: looking for a config must not touch the stick.
#
# The partitions of the boot stick are searched too: this image is written to a
# USB stick, and on a Ventoy or hand-partitioned stick the data partition's root
# is exactly where a config belongs. The partition carrying the live system is
# iso9660 and is skipped below, and the boot disk is never a target, so a config
# found there cannot point the installer at the stick it booted from.
find_config(){
  local m p pk fs
  CFG_EMPTY=""
  while read -r m; do
    [ -n "$m" ] || continue
    cfg_candidate "$m/haos-installer.cfg" && return 0
  done < <(findmnt -rno TARGET 2>/dev/null)

  while read -r p; do
    [ -n "$p" ] || continue
    pk=$(lsblk -no PKNAME "/dev/$p" 2>/dev/null | head -1 | tr -d ' ')
    [ -n "$pk" ] || continue
    case "$(lsblk -dno TRAN "/dev/$pk" 2>/dev/null | tr -d ' ')/$(lsblk -dno RM "/dev/$pk" 2>/dev/null | tr -d ' ')" in
      *usb*|*1*) ;;
      *) continue ;;
    esac
    fs=$(lsblk -no FSTYPE "/dev/$p" 2>/dev/null | tr -d ' ')
    case "$fs" in iso9660|udf|"") continue ;; esac
    mkdir -p /mnt/cfg 2>/dev/null || continue
    mount -o ro "/dev/$p" /mnt/cfg 2>>"$LOG" || continue
    cfg_candidate /mnt/cfg/haos-installer.cfg && return 0
    umount /mnt/cfg 2>>"$LOG" || true
  done < <(lsblk -lno NAME,TYPE 2>/dev/null | awk '$2=="part"{print $1}')

  [ -n "$CFG_EMPTY" ] && logx "config file at $CFG_EMPTY sets nothing (every key commented out): ignored"
  return 1
}

# The disk that carries the config file. target_rows() needs it: a stick holding
# nothing but haos-installer.cfg is an installation medium, and counting it as a
# target would turn "the only disk" into two and stop a machine that was ready.
cfg_medium_disk(){
  local src
  [ -n "${CFG_MNT:-}" ] || return 0
  src=$(findmnt -no SOURCE "$CFG_MNT" 2>/dev/null) || return 0
  [ -n "$src" ] || return 0
  lsblk -no PKNAME "$src" 2>/dev/null | head -1 | tr -d ' '
}

# Where the decisions came from, for the log and the banner: the image's own
# config, a file on a medium and the kernel command line can all have spoken,
# and a bug report that names only the last one is a report about the wrong file.
cfg_source(){
  local s=""
  [ -n "${CFG_IMAGE_FILE:-}" ] && s="$CFG_IMAGE_FILE"
  [ -n "${CFG_FILE:-}" ] && s="${s:+$s + }$CFG_FILE"
  printf '%s' "${s:-/proc/cmdline}"
}

# Decides whether this run is unattended, and stops at once when a config asks
# for a disk to be erased without saying WIPE=yes. The kernel command line is
# applied last, so the person who just edited the boot entry wins over a file
# left on the stick.
load_config(){
  local p kv baked
  # Overridable so that tests/unattended.sh can feed it a canned command line
  # without touching the machine it runs on.
  local cmd="${HAOS_CMDLINE:-/proc/cmdline}"
  baked="${HAOS_IMAGE_CFG:-/etc/haos-installer.cfg}"

  # Layered, weakest first: the config a build put into the image (the
  # unattended ISO has one), then a file found on a medium, then the kernel
  # command line. Each layer only sets the keys it names, so a two-line stick
  # changes LANG= or POWEROFF= on the unattended image without rebuilding it --
  # and a layer above cannot silently drop a decision made below it.
  if [ -f "$baked" ] && cfg_has_keys "$baked"; then
    CFG_IMAGE_FILE="$baked"
    parse_config_file "$baked" || logx "config built into the image could not be read"
    logx "config built into the image: $baked"
  fi

  if find_config; then
    logx "config file found: $CFG_FILE"
    parse_config_file "$CFG_FILE" || logx "config file could not be read"
    CFG_DISK_DEV=$(cfg_medium_disk)
    [ -n "$CFG_DISK_DEV" ] && logx "config medium is /dev/$CFG_DISK_DEV: never a target"
  else
    logx "no config file on any medium"
  fi

  for p in $(cat "$cmd" 2>/dev/null); do
    case "$p" in
      haos.*=*)
        kv=${p#haos.}
        parse_config_line "${kv%%=*}=${kv#*=}"    # haos.disk=/dev/sda -> DISK=...
        ;;
    esac
  done

  if [ "$CFG_UNATTENDED" != "yes" ]; then
    logx "UNATTENDED is not yes in $(cfg_source): normal wizard"
    return 0
  fi
  UNATTENDED=yes

  if [ -n "$CFG_LANG" ]; then
    if config_supported_lang "$CFG_LANG"; then
      UI_LANG="$CFG_LANG"
    else
      logx "config: LANG=$CFG_LANG is not supported, keeping English"
    fi
  fi
  set_strings
  if [ -n "$CFG_KEYMAP" ]; then
    apply_keymap "${CFG_KEYMAP%%|*}" \
      "$( [ "${CFG_KEYMAP#*|}" != "$CFG_KEYMAP" ] && printf '%s' "${CFG_KEYMAP#*|}" )"
  else
    apply_keymap "$(default_keymap "$UI_LANG")" ""
  fi

  # Erasing a disk with nobody in front of the screen needs consent written down:
  # WIPE=yes is that signature, and its absence stops the run here.
  if [ "$CFG_WIPE" != "yes" ]; then
    die "$(printf "$S_UNAT_NOWIPE" "$(cfg_source)")"
  fi
  return 0
}

unattended_banner(){
  logx "UNATTENDED: config $(cfg_source) | language $UI_LANG | disk ${CFG_DISK:-<the only one>} | image ${CFG_IMAGE:-download} | poweroff ${CFG_POWEROFF:-no} | stream ${CFG_STREAM:-no} | format ${CFG_FORMAT:-no}"
  whiptail --title "$S_TITLE" --infobox \
    "$(printf "$S_UNAT_ACTIVE" "$(cfg_source)" "$UI_LANG")" 13 68
  sleep 2
}

# Picks the image without asking: IMAGE= if the config names one, else the only
# .img.xz found on a stick, else the download. More than one image is ambiguous,
# so it downloads rather than guessing which one someone meant.
unattended_image_source(){
  local path
  if [ -n "$CFG_IMAGE" ]; then
    path="$CFG_IMAGE"
    case "$path" in /*) ;; *) path="${CFG_MNT:-/mnt/cfg}/$path" ;; esac
    if [ ! -f "$path" ]; then
      die "$(printf "$S_IMG_BAD" "$path" "IMAGE=$CFG_IMAGE: file not found")"
    fi
    accept_local_image "$path" \
      || die "$(printf "$S_IMG_BAD" "${path##*/}" "$(tail -n 4 "$LOG" 2>/dev/null | cut -c1-64)")"
    return 0
  fi
  if find_images; then
    if [ "${#IMG_CANDS[@]}" -eq 1 ]; then
      path="${IMG_CANDS[0]%%|*}"
      accept_local_image "$path" \
        || die "$(printf "$S_IMG_BAD" "${path##*/}" "$(tail -n 4 "$LOG" 2>/dev/null | cut -c1-64)")"
      return 0
    fi
    logx "unattended: ${#IMG_CANDS[@]} images on sticks, ambiguous -> download"
  fi
  release_image_mounts ""
  logx "unattended: source download"
  return 0
}

# Chooses the target without asking: DISK= when the config names one (and it is
# eligible by the same rules the menu uses), otherwise the only eligible disk.
# Two eligible disks is ambiguous -> stop, rather than erase the wrong one.
unattended_target(){
  local -a rows=() devs=()
  local rec dev list bytes gb

  mapfile -t rows < <(target_rows)
  for rec in ${rows[@]+"${rows[@]}"}; do devs+=("${rec%%$'\t'*}"); done
  [ "${#devs[@]}" -gt 0 ] || die "$S_DISK_NONE"

  if [ -n "$CFG_DISK" ]; then
    for dev in "${devs[@]}"; do
      [ "$dev" = "$CFG_DISK" ] && TARGET="$dev"
    done
    [ -n "$TARGET" ] || die "$(printf "$S_UNAT_NODISK" "$CFG_DISK")"
    logx "unattended: target from config: $TARGET"
  elif [ "${#devs[@]}" -eq 1 ]; then
    TARGET="${devs[0]}"
    logx "unattended: single eligible disk: $TARGET"
  else
    list=$(printf '  %s\n' "${devs[@]}")
    die "$(printf "$S_UNAT_MULTI" "${#devs[@]}" "$list")"
  fi

  # 32 GB: below that threshold dd would die with "No space left" AFTER erasing.
  bytes=$(blockdev --getsize64 "$TARGET" 2>/dev/null || echo 0)
  gb=$(( bytes / 1000000000 ))
  if [ "$gb" -lt 32 ]; then
    die "$(printf "$S_DISK_SMALL" "$TARGET" "$gb")"
  fi

  # Unattended is also how a box gets reinstalled, so an existing Home Assistant
  # is not refused -- but it is said in the log, because WIPE=yes was signed for
  # a disk that already held someone's house.
  if lsblk -no LABEL "$TARGET" 2>/dev/null | grep -qix 'hassos-boot'; then
    logx "unattended: $TARGET already carries a Home Assistant installation -- WIPE=yes covers it"
  fi
  logx "unattended: target $TARGET ($(describe_part "$TARGET"), ${gb} GB)"
  return 0
}

# Two targets, success on either: a network that filters github.com used to be
# read as "no internet" while the image itself was perfectly reachable -- and a
# captive portal that answers for github.com would give the opposite lie.
have_net(){
  # Short timeouts on purpose: this is called in loops, and a network that never
  # answers must not make the wizard look hung for ten seconds at a time.
  curl -fsI --connect-timeout 2 --max-time 4 https://github.com >/dev/null 2>&1 && return 0
  curl -fsI --connect-timeout 2 --max-time 4 https://version.home-assistant.io/stable.json >/dev/null 2>&1
}

# Polls instead of sleeping a fixed time: when the cable is already up this
# returns on the first try, and when it is plugged in late it reacts within half
# a second instead of waiting out a whole sleep.
wait_net(){ local i; for i in $(seq 1 "${1:-10}"); do have_net && return 0; sleep 0.5; done; return 1; }

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
# installation medium (fragile when mounted, breaks Ventoy, lost on the next
# flash). Unnecessary anyway: a written stick already exposes its ESP as FAT.
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
# Is the boot medium something we can honestly offer to reformat? Only a whole,
# writable, removable or USB-attached disk qualifies. A virtual CD -- the usual
# boot medium in a virtual machine, /dev/sr0 with TYPE "rom" -- an internal disk
# or a device-mapper/loop device does not, and telling the user "the stick could
# not be reformatted" there is misleading noise at the end of an installation
# that went perfectly well.
can_reformat_medium(){
  local d="${1:-}" type rm tran
  [ -n "$d" ] || return 1
  [ -b "/dev/$d" ] || return 1
  case "$d" in dm-*|loop*|md*|sr*) return 1 ;; esac
  type=$(lsblk -dno TYPE "/dev/$d" 2>/dev/null | tr -d ' ')
  [ "$type" = "disk" ] || return 1
  rm=$(lsblk -dno RM "/dev/$d" 2>/dev/null | tr -d ' ')
  tran=$(lsblk -dno TRAN "/dev/$d" 2>/dev/null | tr -d ' ')
  case "$rm$tran" in
    *1*|*usb*) return 0 ;;                 # removable, or on the USB bus
  esac
  return 1                                 # fixed internal disk: leave it alone
}

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

  # Typed confirmation, exactly like the disk step: the stick is the only way
  # back into the installer, so a stray keypress must not be able to destroy it.
  local ans msg
  msg="$(printf "$S_FMT_ASK" "$(describe_part "/dev/$dev")")$'\n\n'$S_FMT_TYPE"
  wt_dims "$msg"
  ans=$(whiptail --title "$S_WARN${STEP:+  [$STEP]}" $WT_SCROLL \
        --inputbox "$msg" "$WT_H" "$WT_W" 3>&1 1>&2 2>&3) \
    || { logx "reformat refused by the user"; return 1; }
  ans=$(printf '%s' "$ans" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
  if [ "$ans" != "YES" ]; then
    logx "reformat refused: YES not typed"
    return 1
  fi

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
  wait_net 10 && return 0            # up to 5 s, but only as long as it needs

  # Unattended: wait longer for an Ethernet link, and never fall into the Wi-Fi
  # menu -- a prompt nobody answers is a hang. The offline path never gets here
  # (an image on a stick needs no network), so failing is the honest answer.
  if [ -n "$UNATTENDED" ]; then
    wait_net 20 || die "$S_UNAT_NONET"
    return 0
  fi

  # No connection yet: ask explicitly for a LAN cable, with a Retry button.
  # That is the usual case on a desktop PC, and someone who simply plugged the
  # cable in late must not be pushed into the Wi-Fi scan menu.
  while ! have_net; do
    wt_yesno "$S_WARN" "$S_LAN_ASK" \
      --yes-button "$S_LAN_RETRY" --no-button "$S_LAN_WIFI" || break
    whiptail --title "$S_TITLE" --infobox "$S_NET_ETH" 7 62
    wait_net 6
  done
  have_net && return 0

  rfkill unblock all 2>/dev/null || true
  nmcli radio wifi on 2>/dev/null || true

  # Poll for the radio instead of sleeping: on a desktop with no Wi-Fi card the
  # fixed sleep was pure loss, and when there is one it usually shows up in well
  # under two seconds.
  local wifi_if="" i
  for i in $(seq 1 10); do
    wifi_if=$(nmcli -t -f DEVICE,TYPE dev status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')
    [ -n "$wifi_if" ] && break
    sleep 0.3
  done
  if [ -z "$wifi_if" ]; then
    local diag
    diag=$( { ip -br link 2>/dev/null; nmcli dev status 2>/dev/null;
              rfkill list 2>/dev/null; dmesg 2>/dev/null | grep -i firmware | tail -4; } \
            | cut -c1-62 | head -18 )
    wt_msg "$S_TITLE" "$(printf "$S_NET_NOWIFI" "$diag")"
  fi

  while true; do
    whiptail --title "$S_TITLE" --infobox "$S_NET_SCAN" 7 62
    nmcli dev wifi rescan 2>/dev/null || true
    # The results matter, not the rescan: poll for a non-empty list instead of
    # always paying three seconds, which the menu used to do on every pass.
    for i in 1 2 3 4 5 6 7 8; do
      nmcli -t -f SSID dev wifi list 2>/dev/null | grep -q . && break
      sleep 0.5
    done

    local menu=() ssid sig sec
    while IFS=$'\t' read -r ssid sig sec; do
      [ -n "$ssid" ] || continue
      menu+=("$ssid" "$(printf 'signal %3s%%   %s' "$sig" "${sec:-open}")")
    # --escape no + a tab separator: the default terse output separates fields
    # with ': ' and escapes a ':' INSIDE an SSID as '\:', so awk -F: split the
    # name and 'nmcli dev wifi connect' was handed the escaped form -- the
    # connection then failed on a network that was plainly visible.
    done < <(nmcli -t --escape no --separator $'\t' -f SSID,SIGNAL,SECURITY \
               dev wifi list 2>/dev/null \
             | awk -F'\t' 'length($1) && !seen[$1]++ {print $1"\t"$2"\t"$3}')

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
# Every rule that decides whether a disk may be erased lives here, once: the live
# medium, the disk holding the image, anything carrying an iso9660, and a Ventoy
# stick are all excluded. Prints one TAB-separated record per eligible disk:
#   /dev/name  size  transport  SSD|HDD  vendor model  is-removable
# pick_disk() renders them as a menu; unattended_target() counts and picks from
# them. Two copies of these exclusions would drift, and a drift erases a disk.
target_rows(){
  local name size model vendor tran rm_ hp kind usb
  # No eval on lsblk output: a MODEL field containing a quote would break the
  # parsing. One column at a time, otherwise an empty field shifts the following
  # ones when read back.
  while read -r name; do
    [ -n "$name" ] || continue
    [ -n "$live_dev" ] && [ "$name" = "$live_dev" ] && continue   # never the boot medium
    # Never the disk we are reading the image from: the write would overwrite
    # the very bytes still to be read.
    [ -n "${IMG_DISK:-}" ] && [ "$name" = "$IMG_DISK" ] && continue
    # Same for the stick that only carries the config file (see cfg_medium_disk).
    [ -n "${CFG_DISK_DEV:-}" ] && [ "$name" = "$CFG_DISK_DEV" ] && continue
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
    # ROTA=1 is a spinning disk: worth knowing before choosing, since an old
    # 3.5" drive is not what anyone wants under Home Assistant.
    kind=$(lsblk -dno ROTA    "/dev/$name" 2>/dev/null | xargs)
    case "${kind:-}" in 0) kind="SSD" ;; 1) kind="HDD" ;; *) kind="-" ;; esac

    usb=0
    if [ "${rm_:-0}" = "1" ] || [ "${hp:-0}" = "1" ] || [ "$tran" = "usb" ]; then
      usb=1
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "/dev/$name" "${size:-?}" "${tran:-?}" \
      "$kind" "$(echo "$vendor ${model:-?}" | xargs)" "$usb"
  done < <(lsblk -dno NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1}')
}

pick_disk(){
  local menu=() dev size tran kind desc usb tag
  # Unattended picks the disk itself, by the rules in target_rows.
  if [ -n "$UNATTENDED" ]; then
    unattended_target
    return $?
  fi

  while IFS=$'\t' read -r dev size tran kind desc usb; do
    [ -n "$dev" ] || continue
    # whiptail cannot colour a menu item -> textual marking at the front.
    tag=""
    if [ "$usb" = "1" ]; then
      case "$UI_LANG" in
        fr) tag="[!! USB / EXTERNE !!] " ;;
        de|nl|sv) tag="[!! USB / EXTERN !!] " ;;
        da|no)    tag="[!! USB / EKSTERN !!] " ;;
        es|pt)    tag="[!! USB / EXTERNO !!] " ;;
        it)       tag="[!! USB / ESTERNO !!] " ;;
        pl)       tag="[!! USB / ZEWNETRZNY !!] " ;;
        cs)       tag="[!! USB / EXTERNI !!] " ;;
        fi)       tag="[!! USB / ULKOINEN !!] " ;;
        ru)       tag="[!! USB / VNESHNIY !!] " ;;
        *)  tag="[!! USB / EXTERNAL !!] " ;;
      esac
    fi
    menu+=("$dev" "$(printf '%s%-9s %-5s %-4s %s' "$tag" "$size" "$tran" "$kind" "$desc")")
  done < <(target_rows)

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

  # A disk that already carries a Home Assistant installation: the user is about
  # to erase a WORKING system, configuration, add-ons and history included. Say
  # it in the confirmation itself, above the partition list.
  local ha="" labels
  labels=$(lsblk -no LABEL "$TARGET" 2>/dev/null)
  if printf '%s\n' "$labels" | grep -qix 'hassos-boot' \
  || printf '%s\n' "$labels" | grep -qix 'hassos-data'; then
    ha="$(printf '%s\n\n' "$S_DISK_HA")"
    logx "target $TARGET already carries a Home Assistant installation"
  fi

  # Typed confirmation, not a button: on this single step a stray Enter or arrow
  # key must not be able to erase a disk. The word YES is deliberately the same
  # in every language, so the check never depends on the UI language; the
  # comparison ignores case and surrounding spaces, but an empty answer stops.
  local ans msg
  msg=$(printf "$S_DISK_CONFIRM" "$TARGET" "$ha$content")
  wt_dims "$msg"
  ans=$(whiptail --title "$S_CONFIRM_T${STEP:+  [$STEP]}" $WT_SCROLL \
        --inputbox "$msg" "$WT_H" "$WT_W" 3>&1 1>&2 2>&3) || die "$S_CANCELLED"
  ans=$(printf '%s' "$ans" | tr -d '[:space:]' | tr '[:lower:]' '[:upper:]')
  [ "$ans" = "YES" ] || die "$S_STOPPED"
  logx "target confirmed: $(describe_part "$TARGET"), ${gb} GB"
  logx "live medium excluded: ${live_dev:-<not identified>}"
}

# ---------------------------------------------------------------------------
# ---- helpers used by flash() -------------------------------------------------

# Average throughput for the log: "0.2 MiB/s" in a bug report is worth far more
# than "it was slow".
rate_mib(){ awk -v b="${1:-0}" -v t="${2:-0}" 'BEGIN{ if (t > 0) printf "%.1f", b/1048576/t; else printf "0.0" }'; }

# Erases the target. Its own function so that the order inside flash() --
# download, check, ERASE, write -- is visible at a glance.
prepare_disk(){
  whiptail --title "$S_TITLE" --infobox "$(printf "$S_PREP" "$TARGET")" 7 62
  logx "erasing $TARGET: $(lsblk -dno MODEL,SIZE "$TARGET" 2>/dev/null | xargs)"
  wipefs -af "$TARGET" 2>>"$LOG" || true
  dd if=/dev/zero of="$TARGET" bs=1M count=16 conv=fsync 2>>"$LOG" || true
  local bytes seek
  bytes=$(blockdev --getsize64 "$TARGET" 2>/dev/null || echo 0)
  seek=$(( bytes/1048576 - 16 ))
  (( seek > 0 )) && dd if=/dev/zero of="$TARGET" bs=1M seek="$seek" count=16 conv=fsync 2>>"$LOG" || true
  logx "target erased: signatures removed, first and last 16 MiB zeroed"
}

# A writable medium to stage the image on when RAM is too small, so that the disk
# is still erased only after the image is known good.
# Only a USB or external disk qualifies: never the target, never the boot medium,
# and never a read-only-by-design filesystem (iso9660, udf). A partition that is
# not already mounted is mounted here and STAGE_MNT is set so flash() can let go
# of it afterwards; an already-mounted partition is used as-is and never unmounted,
# because we do not unmount what we did not mount.
# Sets STAGE_DIR and returns 0, or returns 1.
find_stage_dir(){
  local need="$1" p pk fs mp avail tgt=""
  STAGE_DIR=""; STAGE_MNT=""
  [ -n "${TARGET:-}" ] && tgt=$(basename "$TARGET")
  while read -r p; do
    [ -n "$p" ] || continue
    pk=$(lsblk -no PKNAME "/dev/$p" 2>/dev/null | head -1 | tr -d ' ')
    [ -n "$pk" ] || continue
    [ -n "$tgt" ] && [ "$pk" = "$tgt" ] && continue
    [ -n "${live_dev:-}" ] && [ "$pk" = "$live_dev" ] && continue
    case "$(lsblk -dno TRAN "/dev/$pk" 2>/dev/null | tr -d ' ')/$(lsblk -dno RM "/dev/$pk" 2>/dev/null | tr -d ' ')" in
      *usb*|*1*) ;;
      *) continue ;;
    esac
    fs=$(lsblk -no FSTYPE "/dev/$p" 2>/dev/null | tr -d ' ')
    case "$fs" in iso9660|udf|"") continue ;; esac    # read-only by design
    mp=$(findmnt -rn -S "/dev/$p" -o TARGET 2>/dev/null | head -1)
    if [ -z "$mp" ]; then
      mp=/mnt/stage
      mkdir -p "$mp" 2>/dev/null || continue
      mount -o rw "/dev/$p" "$mp" 2>>"$LOG" || continue
      STAGE_MNT="$mp"
    fi
    # Mounted read-only (dirty NTFS, Ventoy) or not writable: not a candidate.
    if ! touch "$mp/.haos-stage-test" 2>/dev/null; then
      [ -n "$STAGE_MNT" ] && { umount "$mp" 2>>"$LOG" || true; STAGE_MNT=""; }
      continue
    fi
    rm -f "$mp/.haos-stage-test" 2>/dev/null || true
    avail=$(df --output=avail -k "$mp" 2>/dev/null | tail -1 | tr -d ' ')
    if [ "${avail:-0}" -lt "$need" ]; then
      logx "staging refused on /dev/$p: $(( ${avail:-0} / 1024 )) MiB free, $(( need / 1024 )) MiB needed"
      [ -n "$STAGE_MNT" ] && { umount "$mp" 2>>"$LOG" || true; STAGE_MNT=""; }
      continue
    fi
    logx "staging medium /dev/$p on $mp, $(( ${avail:-0} / 1024 )) MiB free"
    STAGE_DIR="$mp"
    return 0
  done < <(lsblk -lno NAME,TYPE 2>/dev/null | awk '$2=="part"{print $1}')
  return 1
}


# ---------------------------------------------------------------------------
# An image the user already has: for a machine with no network, or for pinning
# the version. Same contract as the download -- the file is checked BEFORE
# anything is erased.
#
# The NAME decides whether the file may be used at all. Writing an image built
# for a Raspberry Pi onto a PC disk produces a disk that boots nothing, and the
# user would learn that only after the erase; so a file that does not carry this
# board's key (generic-x86_64) is reported as unusable rather than offered.
IMG_FILE=""                    # verified local image; "" means "download"
IMG_MNT=""                     # mount point that must stay until the write
IMG_DISK=""                    # disk carrying that image: never a target
IMG_CANDS=()                   # "path|mount point|size"
IMG_FOREIGN=()                 # "name (board)", for the "not usable" message
IMG_MNTS=()                    # every mount point this script created

classify_image(){              # <filename> -> ok | board:<board> | no
  local n b
  n=$(printf '%s' "${1##*/}" | tr 'A-Z' 'a-z')
  case "$n" in *.img.xz) ;; *) printf 'no'; return 0 ;; esac
  case "$n" in haos_*-[0-9]*.img.xz) ;; *) printf 'no'; return 0 ;; esac
  b=$(printf '%s' "$n" | sed -e 's/^haos_//' -e 's/-[0-9][^-]*\.img\.xz$//')
  # Upstream writes generic-x86-64; a file renamed by hand may say generic-x86_64.
  # It is the same board, so the separator is normalised before comparing rather
  # than the name being trusted twice.
  if [ "$(printf '%s' "$b" | tr '_' '-')" = "$HAOS_BOARD" ]; then
    printf 'ok'
  else
    printf 'board:%s' "$b"
  fi
}

image_version(){               # <filename> -> version, or nothing
  printf '%s' "$1" | sed -n 's/^haos_generic-x86[-_]64-\([0-9][0-9.]*\)\.img\.xz$/\1/p'
}

release_image_mounts(){        # <mount point to keep, or "">
  local keep="$1" m
  for m in "${IMG_MNTS[@]:-}"; do
    [ -n "$m" ] || continue
    [ "$m" = "$keep" ] && continue
    umount "$m" 2>>"$LOG" || true
  done
  IMG_MNTS=()
  [ -n "$keep" ] && IMG_MNTS=("$keep")
  return 0
}

# Scans removable media for HAOS images, read-only: the stick belongs to the
# user and must look the same afterwards. Depth 2, because people keep the file
# in a folder. Returns 0 when at least one usable image was found.
find_images(){
  local p pk fs mp f base size verdict tgt="" n=0
  IMG_CANDS=(); IMG_FOREIGN=(); IMG_MNTS=()
  [ -n "${TARGET:-}" ] && tgt=$(basename "$TARGET")
  while read -r p; do
    [ -n "$p" ] || continue
    pk=$(lsblk -no PKNAME "/dev/$p" 2>/dev/null | head -1 | tr -d ' ')
    [ -n "$pk" ] || continue
    [ -n "$tgt" ] && [ "$pk" = "$tgt" ] && continue
    [ -n "${live_dev:-}" ] && [ "$pk" = "$live_dev" ] && continue
    case "$(lsblk -dno TRAN "/dev/$pk" 2>/dev/null | tr -d ' ')/$(lsblk -dno RM "/dev/$pk" 2>/dev/null | tr -d ' ')" in
      *usb*|*1*) ;;
      *) continue ;;
    esac
    fs=$(lsblk -no FSTYPE "/dev/$p" 2>/dev/null | tr -d ' ')
    case "$fs" in iso9660|udf|"") continue ;; esac
    mp=$(findmnt -rn -S "/dev/$p" -o TARGET 2>/dev/null | head -1)
    if [ -z "$mp" ]; then
      n=$(( n + 1 ))
      mp="/mnt/img$n"
      mkdir -p "$mp" 2>/dev/null || continue
      mount -o ro "/dev/$p" "$mp" 2>>"$LOG" || continue
      IMG_MNTS+=("$mp")
    fi
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      base=${f##*/}
      verdict=$(classify_image "$base")
      case "$verdict" in
        ok)
          size=$(stat -c%s "$f" 2>/dev/null || echo 0)
          logx "image candidate: $f ($(numfmt --to=iec "$size" 2>/dev/null || echo "$size"))"
          IMG_CANDS+=("$f|$mp|$size") ;;
        board:*)
          logx "image refused, built for another board: $f (${verdict#board:})"
          IMG_FOREIGN+=("$base (${verdict#board:})") ;;
      esac
    done < <(find "$mp" -maxdepth 2 -type f -iname '*.img.xz' 2>/dev/null | LC_ALL=C sort)
  done < <(lsblk -lno NAME,TYPE 2>/dev/null | awk '$2=="part"{print $1}')
  [ "${#IMG_CANDS[@]}" -gt 0 ]
}

# Accepts <path> as the image to write: .xz integrity first, then where it sits
# is recorded, because the disk carrying it must never be offered as a target.
# Returns 1, leaving IMG_FILE untouched, when the file does not pass its checks.
accept_local_image(){
  local path="$1" rec mnt src ver
  whiptail --title "$S_TITLE" --infobox "$S_IMG_CHECK" 7 66
  xz -t "$path" 2>>"$LOG" || return 1
  mnt=""
  for rec in ${IMG_CANDS[@]+"${IMG_CANDS[@]}"}; do
    [ "${rec%%|*}" = "$path" ] && mnt=$rec
  done
  mnt=${mnt#*|}; mnt=${mnt%%|*}
  IMG_FILE="$path"
  IMG_MNT="$mnt"
  # Reading the image from the disk we write to would corrupt both, so that disk
  # is removed from the target list rather than trusted to the user.
  IMG_DISK=""
  src=$(findmnt -rn -o SOURCE -T "$path" 2>/dev/null | head -1)
  case "$src" in /dev/*) IMG_DISK=$(to_physical_disk "$src" 2>/dev/null) || IMG_DISK="" ;; esac
  logx "image sits on disk ${IMG_DISK:-unknown}: it will not be offered as a target"
  release_image_mounts "$mnt"
  ver=$(image_version "${path##*/}")
  [ -n "$ver" ] && HAOS_VERSION="$ver"
  logx "offline image accepted: $path (${ver:-version unknown}), .xz checks passed"
  return 0
}

# Lets the user pick one of them. Returns 0 with IMG_FILE set, 1 to download.
use_local_image(){
  local choice rec path mnt size ver note detail src
  while :; do
    whiptail --title "$S_TITLE" --infobox "$S_IMG_SCAN" 7 66
    if ! find_images; then
      note="-"
      [ "${#IMG_FOREIGN[@]}" -gt 0 ] && note=$(printf '  %s\n' "${IMG_FOREIGN[@]}")
      release_image_mounts ""
      wt_yesno "$S_WARN" "$(printf "$S_IMG_NONE" "$note")" \
        --yes-button "$S_STAGE_RETRY" --no-button "$S_SRC_DL" || return 1
      continue
    fi

    local -a menu=()
    for rec in "${IMG_CANDS[@]}"; do
      path=${rec%%|*}
      size=${rec##*|}
      menu+=("$path" "$(numfmt --to=iec "$size" 2>/dev/null || echo "$size")")
    done
    choice=$(wt_menu "$S_TITLE" "$S_IMG_PICK" 12 "${menu[@]}") \
      || { release_image_mounts ""; return 1; }

    if accept_local_image "$choice"; then
      return 0
    fi
    detail=$(tail -n 4 "$LOG" 2>/dev/null | cut -c1-64)
    logx "offline image FAILED the .xz check: $choice"
    wt_msg "$S_WARN" "$(printf "$S_IMG_BAD" "${choice##*/}" "$detail")"
    release_image_mounts ""
  done
}

choose_image_source(){
  local choice
  IMG_FILE=""
  if [ -n "$UNATTENDED" ]; then
    unattended_image_source
    return 0
  fi
  choice=$(wt_menu "$S_TITLE" "$S_SRC_ASK" 8 \
             "$S_SRC_DL" "" \
             "$S_SRC_USE" "") || die "$S_CANCELLED"
  if [ "$choice" = "$S_SRC_USE" ]; then
    logx "source: image already on a stick"
    use_local_image && return 0
    logx "source: no usable image on a stick, falling back to the download"
  else
    logx "source: download"
  fi
  IMG_FILE=""
  return 0
}

# Downloads the image with resume and an integrity check; returns 0 only when the
# file is complete AND its .xz checksums validate, so the caller can then erase a
# disk knowing the image is already in hand.
# Resume is only possible because the file is on the disk: curl cannot seek in a
# pipe, and a resume there re-injects bytes into the xz stream and corrupts it.
download_image(){
  local dst="$1" size="$2" have rc detail bad=0
  while :; do
    have=0
    [ -f "$dst" ] && have=$(stat -c%s "$dst" 2>/dev/null || echo 0)
    [[ "$have" =~ ^[0-9]+$ ]] || have=0

    clear
    if (( have > 0 )) && (( have < size )); then
      printf '\n  %s\n\n' "$(printf "$S_DL_RESUME" \
        "$(numfmt --to=iec "$have" 2>/dev/null || echo "$have")" \
        "$(numfmt --to=iec "$size" 2>/dev/null || echo "$size")")"
      # pv only knows the REMAINING bytes, so its bar covers this attempt; the
      # line above already says how much is on disk.
      curl -fSL -C - --speed-limit 1024 --speed-time 30 "$IMG_URL" 2>>"$LOG" \
        | pv -s "$(( size - have ))" >> "$dst"
      rc=${PIPESTATUS[0]}
    elif (( have >= size )) && [ -s "$dst" ]; then
      rc=0                                   # nothing left to fetch
    else
      printf '\n  %s\n\n' "$(printf "$S_WRITING" "$HAOS_VERSION")"
      rm -f "$dst"
      curl -fSL --speed-limit 1024 --speed-time 30 "$IMG_URL" 2>>"$LOG" \
        | pv -s "$size" > "$dst"
      rc=${PIPESTATUS[0]}
    fi

    if [ "$rc" -ne 0 ] || [ ! -s "$dst" ]; then
      detail=$(tail -n 6 "$LOG" 2>/dev/null | cut -c1-64)
      logx "download interrupted (curl code $rc, $(stat -c%s "$dst" 2>/dev/null || echo 0) bytes on disk)"
      # The partial file is KEPT: that is exactly what makes the resume useful.
      if [ -n "$UNATTENDED" ]; then
        die "$(printf "$S_DL_ABORT" "$detail" "$LOG")"
      fi
      wt_yesno "$S_WARN" "$(printf "$S_DL_RETRY" "$rc" "$detail")" \
        || die "$(printf "$S_DL_ABORT" "$detail" "$LOG")"
      continue
    fi

    # Integrity of the DOWNLOAD: xz's own checksums. A truncated or corrupted
    # file is caught here, while the disk is still untouched.
    whiptail --title "$S_TITLE" --infobox "$S_DL_CHECK" 7 62
    if ! xz -t "$dst" 2>>"$LOG"; then
      bad=$(( bad + 1 ))
      logx "downloaded image FAILED the .xz check (attempt $bad of 2)"
      rm -f "$dst"                         # resuming would resume over bad bytes
      (( bad < 2 )) && continue
      die "$(printf "$S_DL_BAD" "$(tail -n 6 "$LOG" 2>/dev/null | cut -c1-64)" "$LOG")"
    fi
    logx "downloaded image passed the .xz integrity check"
    return 0
  done
}

flash(){
  local dl
  if [ -n "${IMG_FILE:-}" ]; then
    # Offline: the size comes from the file itself, there is no URL to ask.
    dl=$(stat -c%s "$IMG_FILE" 2>/dev/null || echo 0)
  else
    dl=$(curl -fsSLI "$IMG_URL" 2>>"$LOG" \
         | awk 'BEGIN{IGNORECASE=1}/^content-length/{v=$2}END{gsub(/\r/,"",v);print v}')
  fi
  [[ "$dl" =~ ^[0-9]+$ ]] && (( dl > 1000000 )) || dl=0     # 0 = size unknown

  # whiptail's stdout is forced onto /dev/tty: otherwise the process substitution
  # inherits the pipe to xz and injects the terminal codes into it.
  local rc=0 avail_kb need_kb usize t0 secs d_file="" stage_h stage_dir
  local -a pvargs

  # Two separate phases give each one its own progress bar -- percent, rate and
  # ETA -- which a single pipeline cannot: it can only ever show one number.
  # That needs the compressed image staged (~450 MB) in RAM, or on a USB medium
  # when RAM is too small; only with neither do we fall back to the streaming
  # pipeline and its single gauge.
  avail_kb=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo 2>/dev/null)
  [[ "$avail_kb" =~ ^[0-9]+$ ]] || avail_kb=0
  need_kb=$(( dl / 1024 * 2 ))            # image + headroom for the write phase

  # Where does the image wait while it is checked? In RAM (a tmpfs) when it fits,
  # otherwise on a stick the user plugs in. Erasing only once the image is known
  # good is the whole point of the two-phase flow, and it used to be lost on
  # low-RAM machines: they fell straight back to a single-pass write. Nothing is
  # erased to find out, so asking costs nothing when the answer is "no medium".
  if [ -n "${IMG_FILE:-}" ]; then
    # Nothing to stage: the image is on the stick the user brought, and it has
    # passed its .xz check. It is read from there as it is.
    d_file="$IMG_FILE"
    logx "offline: writing from $d_file, nothing to stage or fetch"
  elif [ "$dl" -gt 0 ]; then
    if [ "$avail_kb" -gt "$need_kb" ]; then
      d_file=/tmp/haos.img.xz
    else
      stage_h=$(numfmt --to=iec "$dl" 2>/dev/null || echo "$dl bytes")
      while :; do
        find_stage_dir "$need_kb" && { stage_dir="$STAGE_DIR"; break; }
        [ -n "$UNATTENDED" ] && break        # nobody is there to plug a stick in
        wt_yesno "$S_WARN" "$(printf "$S_STAGE_ASK" "$stage_h")" \
          --yes-button "$S_STAGE_RETRY" --no-button "$S_STAGE_STREAM" || break
      done
      if [ -n "$stage_dir" ]; then
        d_file="$stage_dir/haos-$HAOS_VERSION.img.xz"
        logx "RAM too small ($(( avail_kb / 1024 )) MiB free, $(( need_kb / 1024 )) MiB needed): staging on $d_file"
        wt_msg "$S_TITLE" "$(printf "$S_STAGE_INFO" "$d_file")"
      else
        # The single-pass write erases the disk before the download is known to
        # work. Fine when someone chose it after reading the warning; not fine to
        # decide alone, so unattended refuses unless STREAM=yes was written.
        if [ -n "$UNATTENDED" ] && [ -z "$CFG_STREAM" ]; then
          die "$(printf "$S_UNAT_NOSTAGE" "$stage_h")"
        fi
        logx "no staging medium found: single-pass write, the disk is erased first"
      fi
    fi
  fi

  if [ -n "$d_file" ]; then
    if [ -n "${IMG_FILE:-}" ]; then
      # ---- 1/3 skipped: the image came with the user and is already checked.
      logx "offline image checked before the erase: nothing to download"
    else
      # ---- 1/3: fetch. A failure offers a resume; declining stops with the disk
      #      untouched, which is the whole point of doing this first. ----
      t0=$SECONDS
      download_image "$d_file" "$dl"
      secs=$(( SECONDS - t0 ))
      logx "download complete: $(( dl / 1048576 )) MiB in ${secs}s, average $(rate_mib "$dl" "$secs") MiB/s"
    fi

    # ---- 2/3: erase. Only reached with a complete, checksummed image: staged
    #      in RAM, on the medium found by find_stage_dir, or verified on the
    #      stick the user brought. ----
    prepare_disk

    # ---- 3/3: write. The uncompressed size comes from the .xz index, so pv can
    #      show a real percentage and an ETA here too. ----
    usize=$(xz --robot -l "$d_file" 2>/dev/null \
            | awk -F'\t' '$1=="totals"{print $5}')
    [[ "$usize" =~ ^[0-9]+$ ]] && (( usize > 0 )) || usize=""
    pvargs=()
    if [ -n "$usize" ]; then pvargs=(-s "$usize"); fi
    clear
    printf '\n  %s\n\n' "$(printf "$S_WRITE_HEAD" "$TARGET")"
    t0=$SECONDS
    xz -dc "$d_file" 2>>"$LOG" \
      | pv "${pvargs[@]}" 2>/dev/tty \
      | tee >(sha256sum | cut -d' ' -f1 > /tmp/haos-img.sha256) \
            >(wc -c > /tmp/haos-img.size) \
      | dd of="$TARGET" bs=4M conv=fsync 2>>"$LOG"
    rc=$?
    secs=$(( SECONDS - t0 ))
    # Never delete a file the user brought: their stick stays as they gave it.
    [ -z "${IMG_FILE:-}" ] && { rm -f "$d_file" 2>>"$LOG" || true; }
    # Only unmount what find_stage_dir or find_images mounted themselves.
    [ -n "${STAGE_MNT:-}" ] && { sync; umount "$STAGE_MNT" 2>>"$LOG" || true; STAGE_MNT=""; }
    [ -n "${IMG_MNT:-}" ] && { sync; umount "$IMG_MNT" 2>>"$LOG" || true; IMG_MNT=""; }
    if [ -n "$usize" ]; then
      logx "write complete: $(( usize / 1048576 )) MiB in ${secs}s, average $(rate_mib "$usize" "$secs") MiB/s"
    else
      logx "write complete in ${secs}s (uncompressed size unknown, no rate)"
    fi
  else
    # ---- Streaming fallback: download and write interleaved, one gauge. ----
    # Reached only when there is nowhere to stage the image: too little RAM and no
    # writable medium. This is the old worst case, the disk being erased before the
    # download is known to work, and S_STAGE_ASK has just said so.
    prepare_disk
    t0=$SECONDS
    # --speed-limit/--speed-time: without them, a network drop left curl waiting
    # on the TCP timers, 'pv -n' re-emitting the last percentage, and the gauge
    # frozen indefinitely -- the user could not tell "slow" from "dead". Below
    # 1 KB/s for 30 s, curl gives up.
    # No --retry here: without -C - the resume starts from zero and re-injects
    # the bytes into the xz stream, which corrupts it; and -C - is unusable on a
    # pipe, curl being unable to seek in it.
    {
      curl -fSL --speed-limit 1024 --speed-time 30 "$IMG_URL" 2>>"$LOG" \
        | pv -n -s "${dl:-560000000}" 2> >(whiptail --title "$S_TITLE" --gauge \
              "$(printf "$S_WRITING" "$HAOS_VERSION")" 9 72 0 >/dev/tty) \
        | xz -dc 2>>"$LOG" \
        | tee >(sha256sum | cut -d' ' -f1 > /tmp/haos-img.sha256) \
              >(wc -c > /tmp/haos-img.size) \
        | dd of="$TARGET" bs=4M conv=fsync 2>>"$LOG"
    }
    rc=$?
    logx "streaming write finished in $(( SECONDS - t0 ))s (no rate: nothing is staged)"
  fi
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

  # The read-back costs minutes; unattended takes them, because a disk that does
  # not match the image is exactly what nobody is there to notice.
  if [ -z "$UNATTENDED" ]; then
    wt_yesno "$S_TITLE" \
      "$(printf "$S_VFY_ASK" "$(numfmt --to=iec "$size" 2>/dev/null || echo "$size")" "$TARGET")" \
      || return 0
  fi

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
       [ -z "$UNATTENDED" ] && wt_msg "$S_TITLE" "$(printf "$S_WIFI_PUSH" "${WIFI_SSID:-Wi-Fi}")" ;;
    2) [ -z "$UNATTENDED" ] && wt_msg "$S_WARN" "$S_WIFI_PUSH_SKIP" ;; # deliberate refusal, logged
    *) logx "FAILED to inject the Wi-Fi profile: HAOS will boot with no network"
       [ -z "$UNATTENDED" ] && wt_msg "$S_WARN" "$S_WIFI_PUSH_FAIL" ;;
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
  # Offered only on a writable removable medium. Inside a VM the installer boots
  # from a virtual CD: reformatting it is impossible, and the warning used to
  # claim "the USB stick could not be reformatted" about a device that was never
  # a stick. Each skip is logged with its reason, so the next report says why.
  if [ -n "$UNATTENDED" ]; then
    # Unattended never reformats unless the config asked for it: turning the only
    # installer someone has into a blank stick is not an assumed preference.
    if [ "$CFG_FORMAT" = "yes" ] && [ -n "${live_dev:-}" ] && can_reformat_medium "$live_dev"; then
      reformat_stick "$live_dev"; fmt_rc=$?
    fi
  elif [ -z "${live_dev:-}" ]; then
    logx "reformat not offered: boot medium not identified"
  elif ! can_reformat_medium "$live_dev"; then
    logx "reformat not offered: /dev/$live_dev is not a writable removable disk (type '$(lsblk -dno TYPE "/dev/$live_dev" 2>/dev/null | tr -d ' ')', rm '$(lsblk -dno RM "/dev/$live_dev" 2>/dev/null | tr -d ' ')')"
  else
    reformat_stick "$live_dev"; fmt_rc=$?
  fi
  case $fmt_rc in
    0) logmsg="$S_DONE_LOG" ;;
    2) [ -z "$UNATTENDED" ] && wt_msg "$S_WARN" "$S_FMT_FAIL" ;;    # stick intact
    3) [ -z "$UNATTENDED" ] && wt_msg "$S_WARN" "$S_FMT_BROKEN" ;;  # no longer bootable
                                             # 1 = deliberate refusal, nothing to say
  esac

  # 'toram' copied the live system to RAM: the stick is no longer used, so we can
  # ask for it to be removed NOW. The reboot then goes straight into HAOS, with
  # no risk of restarting the installer or removing the stick too early.
  if [ -n "$UNATTENDED" ]; then
    # The log is worth keeping whether or not the stick was reformatted: on a
    # headless box it is the only evidence of what happened.
    try_write_log "$LOG" >/dev/null 2>&1 || true
    if [ "$CFG_POWEROFF" = "yes" ]; then
      printf '%s\n' "$(printf "$S_UNAT_OFF_HALT" "$TARGET" | sed 's/\\n/\n/g')"
    else
      printf '%s\n' "$(printf "$S_UNAT_OFF_REBOOT" "$TARGET" | sed 's/\\n/\n/g')"
    fi
    sleep 15
    if [ "$CFG_POWEROFF" = "yes" ]; then
      logx "UNATTENDED: powering off (POWEROFF=yes)"
      halt_now
      exit 0                   # never fall through into the wizard screen
    fi
    logx "UNATTENDED: rebooting into Home Assistant OS"
    clear; reboot
  fi
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
# Unattended mode (opt-in: a config file on a stick, or the kernel cmdline). All
# of these stay empty in the normal wizard, which is what every branch below tests.
UNATTENDED=""                 # "yes" once a config asked for it
CFG_FILE=""                   # config file that was read (empty = kernel cmdline)
CFG_MNT=""                    # where that file is mounted, for IMAGE= paths
CFG_EMPTY=""                  # a template-only file seen on the way: only logged
CFG_IMAGE_FILE=""             # config built into the image itself (unattended ISO)
CFG_DISK_DEV=""                    # disk carrying that file: never a target
# Declared although no branch below needs it: parse_config_line writes it, so a
# config could, and 'set -u' turns reading a config *without* UNATTENDED= into a
# crash of the whole wizard. Every CFG_* key read anywhere needs its line here.
CFG_UNATTENDED=""              # UNATTENDED=yes: the opt-in itself
CFG_WIPE=""                   # WIPE=yes: consent to erase, replaces the typed YES
CFG_DISK=""                   # DISK=: the target, or empty to take the only one
CFG_IMAGE=""                  # IMAGE=: a .img.xz next to the config file
CFG_LANG=""                   # LANG=: two-letter language
CFG_KEYMAP=""                 # KEYBOARD=: console layout (default from LANG)
CFG_POWEROFF=""               # POWEROFF=yes: power off instead of rebooting
CFG_STREAM=""                 # STREAM=yes: allow erasing before the check
CFG_FORMAT=""                 # FORMAT=yes: keep the reformat-the-stick offer
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
load_config                 # opt-in: a config file on a stick, or the cmdline
if [ -n "$UNATTENDED" ]; then
  unattended_banner         # language and keyboard already set from the file
else
  choose_lang_keyboard
fi
# Requirements state in the log: it is the first thing to look at when HAOS does
# not boot after an otherwise successful installation.
logx "installer started -- language $UI_LANG, board $HAOS_BOARD"
BOOT_STATE=$(boot_status); SB_STATE=$(secureboot_status)
logx "boot: $BOOT_STATE | Secure Boot: $SB_STATE"
# Build stamp written by build-iso.sh: without it, a bug report cannot say which
# ISO it came from, and every "it fails" starts with guessing.
BUILD_STAMP=""
if [ -r /etc/haos-installer-build ]; then
  BUILD_STAMP=$(head -1 /etc/haos-installer-build 2>/dev/null | tr -d '\r' | cut -c1-40)
fi
STEP="1/6"                  # progress marker shown in every window title
WELCOME_TEXT=$(printf "$S_WELCOME" "$BOOT_STATE" "$SB_STATE")
if [ -n "$BUILD_STAMP" ]; then
  logx "installer build: $BUILD_STAMP"
  WELCOME_TEXT="$WELCOME_TEXT"$'\n\n'"$BUILD_STAMP"
fi
# Unattended: the banner already said what is about to happen, and a box waiting
# for an OK button is a box that never installs.
[ -z "$UNATTENDED" ] && wt_msg "$S_TITLE" "$WELCOME_TEXT"
STEP="2/6"
choose_image_source         # download, or an image the user brings on a stick
if [ -z "${IMG_FILE:-}" ]; then
  setup_network
  log_active_net            # after setup_network: covers all of its exit points
  STEP="3/6"
  resolve_version           # REQUIRES the network: must stay after setup_network
else
  logx "network and version steps skipped: using an offline image"
fi
STEP="4/6"
pick_disk
STEP="5/6"
flash
verify
STEP="6/6"
finalize
