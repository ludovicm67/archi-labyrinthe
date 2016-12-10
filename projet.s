.data

    # Textes pour les différentes demandes
    TexteDemanderNom:
        .asciiz "Entrez un nom de fichier (sans extension) : "
    TexteMenu:
        .asciiz "\nMENU :\n 1 - Génération d'un labyrinthe\n 2 - Résolution d'un labyrinthe\n\nEntrez votre choix : "
    TexteDemanderN:
        .asciiz "Veuillez entrer un entier N compris entre 2 et 99 : "

    # Textes pour l'affichage des erreurs
    TexteErreurFichier404:
        .asciiz "\n\tLe fichier '"
    TexteErreurFichier404Fin:
        .asciiz "' n'existe pas. Veuillez réessayer !\n\n"

    # On réserve de la place (buffer, nom du fichier)
    fichier:
        .space 1024     # On réserve de la place pour stocker le nom du fichier
    buffer:
        .space 1        # On initialise un buffer de taille 1

    # Extensions à ajouter, pour le nom de fichier
    ExtTxt:
        .asciiz ".txt"
    ExtResolu:
        .asciiz ".resolu"


.text
.globl __start

# Point d'entrée du programme
__start:

    # On demande le nom du fichier avec lequel on va travailler
    la $a0 TexteDemanderNom         # On charge l'adresse de TexteDemanderNom dans $a0
    li $v0 4                        # On dit que l'on souhaite afficher une chaine de caractères
    syscall                         # On effectue l'appel système

    la $a0 fichier                  # L'emplacement où on va stocker la chaîne demandée
    li $a1 1013                     # Taille max du buffer (1024 - longueur(".txt.resolu"))
    li $v0 8                        # Appel système pour demander une chaine de caractères
    syscall
    move $t0 $a0                    # Adresse du caractère courant

    # On enlève le saut de ligne
    EnleveRetChar:
    lb $a0 0($t0)                   # On récupère le caractère courant
    beq $a0 10 FinEnleveRetChar     # Si on a '\n', alors on sort de la boucle
    beqz $a0 FinEnleveRetChar       # Si on a '\0', alors on sort de la boucle
    addi $t0 $t0 1                  # Sinon on incrémente l'offset
    j EnleveRetChar                 # ...et on rentre à nouveau dans la boucle
    FinEnleveRetChar:
    sb $0 0($t0)                    # On écrase le '\n' par '\0'

    # On ajoute l'extension '.txt'
    la $a0 fichier
    la $a1 ExtTxt
    jal Concatener

    # On peut désormais passer au menu :)
    j Menu


# Permet de concaténer deux chaînes de caractères (ajoute de la seconde chaîne à la fin de la première)
## Entrées : $a0 = adresse de début de la première chaîne de caractères
##           $a1 = adresse de début de la seconde chaîne de caractères
Concatener:

    # Prologue
    subu $sp $sp 12
    sw $a0 8($sp)
    sw $s0 4($sp)
    sw $s1 0($sp)

    move $s0 $a0                        # On sauvegarde $a0 dans $s0
    move $s1 $a1                        # On sauvegarde $a1 dans $s1

    # On parcourt la première chaîne de caractère (pour avoir l'adresse de fin de la chaîne)
    ParcourirPremiereChaine:
    lb $a0 0($s0)                       # $a0 : caractère courant
    beqz $a0 ParcourirDeuxiemeChaine    # Si on est à la fin de la première chaine, on passe à la seconde
    addi $s0 $s0 1                      # Sinon on continue à parcourir la chaîne
    j ParcourirPremiereChaine

    # On ajoute chaque caractère de la seconde chaîne à la suite de la première
    ParcourirDeuxiemeChaine:
    lb $a0 0($s1)                       # $a0 : caractère courant
    beqz $a0 FinConcatener              # Si on est à la fin de la 2ème chaine, on a fini
    sb $a0 0($s0)                       # ...sinon on ajoute le caractère courant à la suite de la 1ère chaîne
    addi $s0 $s0 1                      # On incrémente le "curseur de la 1ère chaîne" de 1
    addi $s1 $s1 1                      # On incrémente le "curseur de la 2ème chaîne" de 1
    j ParcourirDeuxiemeChaine

    # Epilogue
    FinConcatener:
    lw $a0 8($sp)
    lw $s0 4($sp)
    lw $s1 0($sp)
    addu $sp $sp 12

    jr $ra


# On affiche le menu
Menu:
    la $a0 TexteMenu                # On charge l'adresse de TexteMenu dans $a0
    li $v0 4                        # On dit que l'on souhaite afficher une chaîne de caractère
    syscall                         # On effectue l'appel système
    li $v0 5                        # On demande à l'utilisateur de saisir un entier (sera stocké dans $v0)
    syscall                         # On effectue l'appel système
    beq $v0 1 GenererLabyrinthe     # Choix 1 - Générer un labyrinthe
    beq $v0 2 ResoudreLabyrinthe    # Choix 2 - Résoudre un labyrinthe
    j Menu                          # Choix de l'utilisateur inexistant -> on lui redemande


# Génération d'un labyrinthe
GenererLabyrinthe:

    # On demande la taille N du labyrinthe à l'utilisateur
    DemanderN:
    la $a0 TexteDemanderN   # Chargement de la chaîne de caractère TexteDemanderN dans $a0
    li $v0 4                # Affichage de la chaîne TexteDemanderN
    syscall                 # Appel système
    li $v0 5                # On lit l'entier que l'utilisateur a entré
    syscall
    move $a0 $v0            # On déplace la valeur que l'utilisateur a entré dans $a0
    blt $a0 2 DemanderN     # Si $a0<2, alors on lui redemande
    bgt $a0 99 DemanderN    # Idem si $a0>99

    move $s0 $a0            # On deplace la valeur que l'utilisateur a entré dans $s0
    mul $a0 $s0 $s0         # Taille du tableau à créer (N*N)
    jal CreerTableau        # $v0 contiendra l'adresse du premier élément du tableau

    move $a0 $s0            # On met $a0 à la valeur entrée par l'utilisateur, qui a été stockée dans $s0
    move $a1 $v0            # on fait en sorte que $a1 contienne l'adresse du premier élément du tableau

    jal ConstruireLabyrinthe
    jal SauvegarderTableau

    j Exit


# Permet de construire le labyrinthe (casser les murs, etc...)
## Entrée : $a0 = N
##          $a1 = adresse du premier élément du tableau
ConstruireLabyrinthe:

    # Prologue
    subu $sp $sp 24
    sw $a0 20($sp)
    sw $a1 16($sp)
    sw $s0 12($sp)
    sw $s1 8($sp)
    sw $s2 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    move $s0 $a0            # $s0 = N
    move $s1 $a1            # $s1 = adresse du premier élément du tableau
    move $a2 $a0            # $a2 = N

    jal PlacerDepartEtArrivee # $v0 contient l'indice de la case départ

    move $a0 $s1            # $a0 = adresse du premier élément du tableau
    move $a1 $v0            # $a1 = case courante (initialisée à l'indice de la case de départ)
    jal MarqueVisite        # Marque la case courante comme visitée

    subu $sp $sp 4
    sw $a1 0($sp)
    li $s2 4                # Compteur

    BoucleConstruireLabyrinthe:
    jal Voisin              # On cherche un voisin pour la case courante
    beq $v0 -1 MarcheArriere # Si aucun voisin (-1), alors on fait marche arrière (dépiler)
    move $a2 $v0            # Sinon on stocke l'indice du voisin dans $a2
    move $a3 $v1            # ...et la direction dans $a3
    jal DetruireMurs        # On détruit le mur entre les deux cases
    move $a1 $a2            # Indice du voisins, que l'on déclare comme nouvelle case courante
    jal MarqueVisite        # Marque la case courante comme visitée
    move $a2 $s0            # On remet $s0 à la valeur de N
    subu $sp $sp 4          # On fait de la place sur la pile
    sw $a1 0($sp)           # ...et on y stocke l'indice de la case courante
    addi $s2 $s2 4          # ...et on incrémente le compteur
    j BoucleConstruireLabyrinthe

    MarcheArriere:
    addu $sp $sp 4          # On dépile
    subi $s2 $s2 4          # On décrémente le compteur
    ble $s2 4 FinBoucleConstruireLabyrinthe # Si on retombe sur la case de départ, c'est qu'on a fini
    lw $a1 0($sp)           # On récupère l'indice de la case précédente
    j BoucleConstruireLabyrinthe # On continue à construire le labyrinthe

    # Epilogue
    FinBoucleConstruireLabyrinthe:
    addu $sp $sp 4          # Case de départ
    mul $a1 $a2 $a2         # $a1 = taille tu tableau (N*N)
    jal EnleverViste        # On enlève les marques que l'on a laissés pour dire qu'une case a été visitée

    lw $a0 20($sp)
    lw $a1 16($sp)
    lw $s0 12($sp)
    lw $s1 8($sp)
    lw $s2 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 24

    jr $ra


# Permet de créer un tableau pour stocker le labyrinthe, avec par défaut des murs partout pour chaque case (case de valeur 15)
## Entrée : $a0 = taille du tableau
## Sortie : $v0 = adresse du premier élément du tableau
CreerTableau:

    # Prologue
    subu $sp $sp 8
    sw $a0 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    li $t0 0        # Compteur pour la boucle
    li $t5 15       # Valeur pour remplir le tableau

    li $v0 9        # On récupère l'adresse du premier élément du tableau
    syscall         # $v0 contiendra donc l'adresse du premier élément du tableau

    BoucleCreerTableau:
    beq $t0 $a0 FinBoucleCreerTableau   # si $t0=$a0 ($t0:compteur, $a0: taille) alors c'est qu'on a rempli le tableau
    addu $t1 $v0 $t0            # Sinon on ajoute la valeur du compteur à l'adresse pour se déplacer dans le tableau et on met ça dans $t1
    sb $t5 0($t1)               # On remplit la case courante du tableau (à l'adresse $t1) avec 15 (la valeur de $t5)
    addu $t0 $t0 1              # On incrémente le compteur de 1
    j BoucleCreerTableau        # On recommence (:

    # Epilogue
    FinBoucleCreerTableau:
    lw $a0 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 8

    jr $ra


# Permet d'enlever le marquage de toutes les cases visitées du labyrinthe
## Entrée : $a0 = adresse du premier élément du tableau
##          $a1 = taille du tableau
EnleverViste:

    # Prologue
    subu $sp $sp 8
    sw $a0 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    li $t0 -1                       # Compteur pour la boucle (initialisé à -1, car on va commencer par incrémenter dans la boucle)
    li $t5 128                      # Valeur à ajouter pour les cases du labyrinthe

    BoucleEnleverViste:
    addu $t0 $t0 1                  # On incrémente le compteur de 1
    beq $t0 $a1 FinBoucleEnleverViste # Si $t0=$a0 ($t0:compteur, $a1: taille) alors c'est qu'on a rempli le tableau
    addu $t1 $a0 $t0                # Sinon on ajoute la valeur du compteur à l'adresse pour se déplacer dans le tableau et on met ça dans $t1
    lb $t2 0($t1)                   # On récupère la valeur de la case
    bge $t2 $0 BoucleEnleverViste   # Si cette case a une valeur positive, on passe directement à la case suivante
    add $t2 $t2 $t5                 # Sinon on lui ajoute 128

    sb $t2 0($t1)                   # On remplit la case courante du tableau (à l'adresse $t1) avec la nouvelle valeur
    j BoucleEnleverViste            # On recommence (:

    # Epilogue
    FinBoucleEnleverViste:
    lw $a0 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 8

    jr $ra


# Permet de modifier une valeur d'une case du labyrinthe
## Entrée : $a0 = adresse du 1er élément du tableau
##          $a1 = indice du premier élément à modifier
##          $a2 = nouvelle valeur
ModifieTableau:

    # Prologue
    subu $sp $sp 8
    sw $s0 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    add $s0 $a0 $a1     # Bonne adresse pour la case à modifier
    sb $a2 0($s0)       # On met la case désirée à la nouvelle valeur

    # Epilogue
    lw $s0 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 8

    jr $ra


# Permet d'afficher le contenu d'un tableau carré (N*N)
## Entrée : $a0 = N, le nombre de lignes/colonnes (prec : $a0>=0)
##          $a1 = adresse du premier élément du tableau
SauvegarderTableau:

    # Prologue
    subu $sp $sp 24
    sw $s0 20($sp)
    sw $s1 16($sp)
    sw $a0 12($sp)
    sw $a1 8($sp)
    sw $a2 4($sp)
    sw $ra 0($sp)

    # Ouverture du fichier
    la $a0 fichier          # Nom du fichier
    li $a1 1                # On ouvre le fichier en écriture (0 : lecture; 1 écriture, ... 9 : écriture à la fin)
    li $a2 0                # Pas de mode (ignoré)
    li $v0 13               # Appel système pour ouvrir un fichier
    syscall

    move $a3 $v0            # Sauvegarde du descripteur du fichier

    # On récupère les valeurs initiales de $a0, $a1 et $a2
    lw $a0 12($sp)
    lw $a1 8($sp)
    lw $a2 4($sp)

    move $s0 $a0            # $s0 : nombre de cases par ligne/colonne
    mul $t0 $a0 $a0         # $t0 : nombre total de cases
    move $t1 $s0            # $t1 : ième colonne (initialisé à N, dans le but de commencer par un saut de ligne)
    li $t2 0                # $t2 : offset de la case courante du tableau

    jal GetDigits
    li $a0 2                # Nombre d'arguments (soit 1, soit 2), ici 2, car on souhaite écrire les 2 digits
    move $a1 $v0            # Premier digit
    move $a2 $v1            # Deuxième digit
    jal EcrireDansFichier

    BoucleSauvegarderTableau:
    beq $t2 $t0 FinBoucleSauvegarderTableau # Si on a parcouru toutes les cases du tableau, on sort de la boucle

    # On traite ici le cas du saut de ligne
    blt $t1 $s0 ApresSautDeLigne   # Si on est pas encore en fin de ligne, on ne saute pas de ligne
    li $t1 0                # On est à nouveau dans la 0ème colonne
    li $a0 1                # Nombre d'arguments (soit 1, soit 2), ici 1, car on souhaite écrire uniquement '\n'
    li $a1 0x0A             # \n en ascii
    jal EcrireDansFichier

    # On traite ici le cas des espaces entre les nombres
    ApresSautDeLigne:
    beq $t1 0 ApresEspace   # Si on est en début de ligne, pas besoin d'insérer d'espace
    li $a0 1                # Nombre d'arguments (soit 1, soit 2), ici 1, car on souhaite écrire uniquement un espace
    li $a1 0x20             # Espace en ascii
    jal EcrireDansFichier

    ApresEspace:
    lw $a1 8($sp)           # On récupère la valeur initiale de $a1
    addu $t3 $a1 $t2        # $t3 : adresse de la case courante

    # AfficheEntier
    lb $a0 0($t3)           # $a0 contient désormais la valeur de la case courante
    jal GetDigits
    li $a0 2                # Nombre d'arguments (soit 1, soit 2)
    move $a1 $v0            # Premier digit
    move $a2 $v1            # Deuxième digit
    jal EcrireDansFichier

    addu $t2 $t2 1          # On incrémente $t2 de 1 (on avance d'une case du tableau, l'offset augmente donc de 1)
    addu $t1 $t1 1          # On incrémente $t1 de 1 (on avance d'une colonne)

    j BoucleSauvegarderTableau

    # On ferme le fichier
    FinBoucleSauvegarderTableau:
    move $a0 $a3            # Descripteur du fichier à fermer
    li $v0 16               # Appel système pour fermer un fichier
    syscall

    # Epilogue
    lw $s0 20($sp)
    lw $s1 16($sp)
    lw $a0 12($sp)
    lw $a1 8($sp)
    lw $a2 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 24

    jr $ra


# Retourne un nombre entier sur 2 digits (convertis en caractères)
## Entrée : $a0 = le nombre à retourner sous forme de 2 digits (prec : 0 <= $a0 <= 99)
## Sortie : $v0 = le premier digit du nombre, sous forme de caractère
##          $v1 = le second digit du nombre, sous forme de caractère
GetDigits:
    li $v0 0                # Par défaut le premier digit vaut 0
    move $v1 $a0            # On met par défaut v1 à la valeur de a0
    blt $a0 10 FinGetDigits # Si $a0 <= 10, alors on a fini

    # Si le nombre est supérieur ou égal à 10, ont doit changer les valeurs de sortie
    div $v0 $a0 10          # Le premier digit est donc le résultat de la division entière de $a0 par 10
    mfhi $v1                # ...et le deuxième est le résultat de $a0 mod 10
                            # (stocké dans hi lors de div, que l'on récupère avec mfhi)

    FinGetDigits:
    # On convertit les digis en caractères, en ajoutant 0x30 (30 en héxadécimal, soit 48 en décimal)
    addiu $v0 $v0 0x30      # On convertit le premier digit en caractère
    addiu $v1 $v1 0x30      # On convertit le second digit en caractère

    jr $ra


# Ecrire des caractères dans un fichier
## Entrée : $a0 = nombre d'arguments (soit 1, soit 2)
##          $a1 = premier caractère
##          $a2 = deuxième caractère (si a0 = 2)
##          $a3 = descripteur de fichier
EcrireDansFichier:

    # Prologue
    subu $sp $sp 24
    sw $a0 20($sp)
    sw $a1 16($sp)
    sw $a2 12($sp)
    sw $s0 8($sp)
    sw $s1 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    move $a0 $a3            # Descripteur du fichier
    la $a1 buffer           # Adresse du buffer à partir duquel on doit écrire
    lw $s1 16($sp)          # Premier caractère à écrire
    sb $s1 0($a1)           # On place notre caractère dans le buffer
    li $a2 1                # Taille du buffer = 1 (on écrit caractère par caractère)
    li $v0 15               # Appel système pour écrire dans un fichier
    syscall

    lw $s1 20($sp)          # On met $s1 à la valeur originale de $a0
    bne $s1 2 FinEcrireDansFichier  # Si on ne souhaitais pas afficher 2 caractères, on a fini
    lw $s1 12($sp)          # Deuxième caractère à écrire
    sb $s1 0($a1)           # On place notre caractère dans le buffer
    li $v0 15               # Appel système pour écrire dans un fichier
    syscall

    # Epilogue
    FinEcrireDansFichier:
    lw $a0 20($sp)
    lw $a1 16($sp)
    lw $a2 12($sp)
    lw $s0 8($sp)
    lw $s1 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 24

    jr $ra


# Modifie le labyrinthe pour ajouter la case de départ et de fin
## Entrées : $a0 : le nombre de lignes/colonnes du labyrinthe entrée par l'utilisateur
##           $a1 : l'adresse de la première case du tableau
## Sortie :  $v0 : l'indice de la case de départ
PlacerDepartEtArrivee:

    # Prologue
    subu $sp $sp 16
    sw $a0 12($sp)
    sw $a1 8($sp)
    sw $a2 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    move $t0 $a0        # $t0 : N
    move $t1 $a1        # $t1 : adresse de la première case du tableau

    # On génère les emplacements aléatoires des cases départ et de fin
    ## Départ d (sera stockée dans $t2)
    li $a0 0
    move $a1 $t0        # Borne sup = N
    li $v0 42           # Génère un nombre aléatoire dans $a0, 0 <= $a0 < $a1
    syscall
    move $t2 $a0

    ## Arrivée f (sera stockée dans $t3)
    li $a0 0
    move $a1 $t0        # Borne sup = N
    li $v0 42           # Génère un nombre aléatoire dans $a0, 0 <= $a0 < $a1
    syscall
    move $t3 $a0

    # On génère une valeur, qui vaut soit 0, 1, 2, ou 3 pour déterminer la configuration
    li $a0 0
    li $a1 4            # Borne sup = N
    li $v0 42           # Génère un nombre aléatoire dans $a0, 0 <= $a0 < $a1
    syscall
    move $t4 $a0

    # On va donc utiliser la configuration choisie précédemment
    ## Sera stocké dans $t5 l'indice de la case de départ
    ## Dans $t6 l'indice de la case de fin
    ## $t7 permet juste de réaliser des parties d'opérations
    beq $t4 0 config0
    beq $t4 1 config1
    beq $t4 2 config2
    beq $t4 3 config3

    # Configuration 0
    ## Début D : à gauche   D=d*N
    ## Fin F :   à droite   F=f*N + N-1
    config0:
    mul $t5 $t2 $s0     # D
    subi $t6 $t0 1
    mul $t7 $t3 $t0
    add $t6 $t6 $t7     # F
    j ConfigOK

    # Configuration 1
    ## Début D : à droite   D=d*N + N-1
    ## Fin F :   à gauche   F=f*N
    config1:
    subi $t5 $t0 1
    mul $t7 $t2 $t0
    add $t5 $t5 $t7     # D
    mul $t6 $t3 $t0     # F
    j ConfigOK

    # Configuration 2
    ## Début D : en haut    D=d
    ## Fin F :   en bas     F=N*(N-1) + f
    config2:
    move $t5 $t2        # D
    subi $t6 $t0 1
    mul $t6 $t0 $t6
    add $t6 $t6 $t3     # F
    j ConfigOK

    # Configuration 3
    ## Début D : en bas   D=N*(N-1) + d
    ## Fin F :   en haut  F=f
    config3:
    subi $t5 $t0 1
    mul $t5 $t0 $t5
    add $t5 $t5 $t2     # D
    move $t6 $t3        # F

    ConfigOK:
    move $a0 $t1        # Adresse de la première case du tableau
    move $a1 $t5        # Indice de la case de départ
    li $a2 31           # Nouvelle valeur (15 (tous les murs) + 16 (case départ))
    jal ModifieTableau

    move $a1 $t6        # Indice de la case de fin
    li $a2 47           # Nouvelle valeur (15 (tous les murs) + 32 (case fin))
    jal ModifieTableau

    # Epilogue
    move $v0 $t5        # $v0 contient désormais l'indice de la case de départ

    lw $a0 12($sp)
    lw $a1 8($sp)
    lw $a2 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 16

    jr $ra


# Retourne l'indice d'un des voisins
## Entrée : $a0 : adresse du premier élément du tableau contenant le labyrinthe
##          $a1 : indice X de la case courante
##          $a2 : valeur de N entrée au début par l'utilisateur
## Sortie : $v0 : l'indice d'un des voisins choisis aléatoirement (vaut -1 si aucun voisin)
##          $v1 : valeur pour identifier la direction (0 : haut, 1 : droite, 2 : bas, 3 : gauche)
Voisin:

    # Prologue
    subu $sp $sp 32
    sw $a0 28($sp)
    sw $a1 24($sp)
    sw $a2 20($sp)
    sw $a3 16($sp)
    sw $s0 12($sp)
    sw $s1 8($sp)
    sw $s2 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    li $s0 0                        # Compteur du nombre de voisins initialisé à 0
    move $t0 $a1                    # X
    move $t1 $a2                    # N
    div $t2 $t0 $t1
    mfhi $t2                        # X%N

    # Valeurs pour les tests
    subi $t3 $t1 1                  # $t3=N-1
    mul $t4 $t1 $t3                 # $t4=N*(N-1)

    # On cherche les différents voisins disponibles
    beq $t2 0 FinVoisinGauche       # Si X%N = 0 alors pas de voisin à gauche
    subi $a1 $t0 1                  # Sinon l'indice vaut X-1
    jal TesteVisite                 # On vérifie si la case a déjà été visitée
    beq $v0 1 FinVoisinGauche       # Si c'est le cas, ce voisin n'est plus disponible
    addi $s0 $s0 8                  # On incremente le compteur de 8
    subu $sp $sp 8                  # On fait de la place sur la pile pour stocker l'indice de ce voisin
    li $t5 3                        # Direction : gauche
    sw $t5 4($sp)                   # On sauvegarde la direction sur la pile
    sw $a1 0($sp)                   # On sauvegarde l'indice du voisin trouvé sur la pile
    FinVoisinGauche:

    beq $t3 $t2 FinVoisinDroite     # Si X%N = N-1 alors pas de voisin à droite
    addi $a1 $t0 1                  # Sinon l'indice vaut X+1
    jal TesteVisite                 # On vérifie si la case a déjà été visitée
    beq $v0 1 FinVoisinDroite       # Si c'est le cas, ce voisin n'est plus disponible
    addi $s0 $s0 8                  # On incremente le compteur de 8
    subu $sp $sp 8                  # On fait de la place sur la pile pour stocker l'indice de ce voisin
    li $t5 1                        # Direction : droite
    sw $t5 4($sp)                   # On sauvegarde la direction sur la pile
    sw $a1 0($sp)                   # On sauvegarde l'indice du voisin trouvé sur la pile
    FinVoisinDroite:

    blt $t0 $t1 FinVoisinHaut       # Si X<N alors il n'y a pas de voisin en haut
    sub $a1 $t0 $t1                 # Sinon l'indice vaut X-N
    jal TesteVisite                 # On vérifie si la case a déjà été visitée
    beq $v0 1 FinVoisinHaut         # Si c'est le cas, ce voisin n'est plus disponible
    addi $s0 $s0 8                  # On incremente le compteur de 8
    subu $sp $sp 8                  # On fait de la place sur la pile pour stocker l'indice de ce voisin
    li $t5 0                        # Direction : haut
    sw $t5 4($sp)                   # On sauvegarde la direction sur la pile
    sw $a1 0($sp)                   # On sauvegarde l'indice du voisin trouvé sur la pile
    FinVoisinHaut:

    bge $t0 $t4 FinVoisinBas        # Si X >= N*(N-1) alors il n'y a pas de voisin en bas
    add $a1 $t0 $t1                 # Sinon l'infice vaut X+N
    jal TesteVisite                 # On vérifie si la case a déjà été visitée
    beq $v0 1 FinVoisinBas          # Si c'est le cas, ce voisin n'est plus disponible
    addi $s0 $s0 8                  # On incremente le compteur de 8
    subu $sp $sp 8                  # On fait de la place sur la pile pour stocker l'indice de ce voisin
    li $t5 2                        # Direction : bas
    sw $t5 4($sp)                   # On sauvegarde la direction sur la pile
    sw $a1 0($sp)                   # On sauvegarde l'indice du voisin trouvé sur la pile
    FinVoisinBas:

    li $v0 -1                       # Valeur de retour par défaut
    li $v1 -1                       # Valeur de retour par défaut

    div $s1 $s0 8                   # On récupère le nombre de voisins ajoutés sur la pile
    beq $s1 $0 FinVoisin            # Si aucun voisin n'a été trouvé, on a pas besoin de faire ce qui suit

    li $a0 0
    move $a1 $s1                    # Borne sup = $s1
    li $v0 42                       # Génère un nombre aléatoire dans $a0, 0 <= $a0 < $a1
    syscall
    move $s2 $a0
    mul $s2 $s2 8                   # On calcule l'offset pour récupérer le bon voisin
    addu $s2 $sp $s2                # On récupère la bonne adresse sur la pile
    lw $v1 4($s2)                   # $v1 contient désormais la direction (0 : haut, 1 : droite, 2 : bas, 3 : gauche)
    lw $v0 0($s2)                   # $v0 contient désormais l'indice d'un voisin choisi aléatoirement

    addu $sp $sp $s0                # On libère la place sur la pile

    # Epilogue
    FinVoisin:
    lw $a0 28($sp)
    lw $a1 24($sp)
    lw $a2 20($sp)
    lw $a3 16($sp)
    lw $s0 12($sp)
    lw $s1 8($sp)
    lw $s2 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 32

    jr $ra


# Fonction qui sert à détruire les murs
## Entrée : $a0 = adresse du premier élément du tableau
##          $a1 = Indice de la case précédente
##          $a2 = Indice de la nouvelle case
##          $a3 = Valeur de la direction dans laquelle on va (0 : haut, 1 : droite, 2 : bas, 3 : gauche)
DetruireMurs:

    # Prologue
    subu $sp $sp 32
    sw $a1 28($sp)
    sw $a2 24($sp)
    sw $a3 20($sp)
    sw $s0 16($sp)
    sw $s1 12($sp)
    sw $s2 8($sp)
    sw $s3 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    add $s0 $a0 $a1             # $s0 : adresse de la case précédente
    add $s1 $a0 $a2             # $s1 : adresse de la nouvelle case
    lb $s0 0($s0)               # $s0 : valeur de la case précédente du tableau
    lb $s1 0($s1)               # $s1 : valeur de la nouvelle case

    move $s2 $a1                # On sauvegarde l'indice de la case précédente dans $s2
    move $s3 $a2                # On sauvegarde l'indice de la nouvelle case dans $s3

    beq $a3 0 AllerHaut         # Si $a3 vaut 0 cela veut dire que l'on se déplace en haut
    beq $a3 1 AllerDroite       # Si $a3 vaut 1 cela veut dire que l'on se déplace à droite
    beq $a3 2 AllerBas          # Si $a3 vaut 2 cela veut dire que l'on se déplace en bas
    beq $a3 3 AllerGauche       # Si $a3 vaut 3 cela veut dire que l'on se déplace à gauche

    AllerHaut:
    move $a1 $s2
    subi $a2 $s0 1              # On soustrait 1 à la valeur de la case précédente
    jal ModifieTableau          # On détruit le mur du haut de la case précédentee
    move $a1 $s3
    subi $a2 $s1 4              # On soustrait 4 (100 en binaire) à la valeur de la nouvelle case
    jal ModifieTableau          # On détruit le mur du bas de la nouvelle case
    j FinDetruireMurs

    AllerDroite:
    move $a1 $s2
    subi $a2 $s0 2              # On soustrait 2 (10 en binaire) à la valeur de la case précédente
    jal ModifieTableau          # On détruit le mur à droite de la case précédente
    move $a1 $s3
    subi $a2 $s1 8              # On soustrait 8 (1000 en binaire) à la valeur de la nouvelle case
    jal ModifieTableau          # On détruit le mur de gauche de la nouvelle case
    j FinDetruireMurs

    AllerGauche:
    move $a1 $s2
    subi $a2 $s0 8              # On soustrait 8 (1000 en binaire) à la valeur de la case précédente
    jal ModifieTableau          # On détruit le mur à gauche de la case précédente
    move $a1 $s3
    subi $a2 $s1 2              # On soustrait 2 (10 en binaire) à la valeur de la nouvelle case
    jal ModifieTableau          # On détruit le mur de droite de la nouvelle case
    j FinDetruireMurs

    AllerBas:
    move $a1 $s2
    subi $a2 $s0 4              # On soustrait 4 (100 en binaire) à la valeur de la case précédente
    jal ModifieTableau          # On détruit le mur du bas de la case précédente
    move $a1 $s3
    subi $a2 $s1 1              # On soustrait 1 à la valeur de la nouvelle case
    jal ModifieTableau          # On détruit le mur du haut de la nouvelle case
    j FinDetruireMurs

    # Epilogue
    FinDetruireMurs:
    lw $a1 28($sp)
    lw $a2 24($sp)
    lw $a3 20($sp)
    lw $s0 16($sp)
    lw $s1 12($sp)
    lw $s2 8($sp)
    lw $s3 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 32

    jr $ra


# Permet de marquer une case comme visitée
## Entrée : $a0 = adresse du premier élément du tableau
##          $a1 = indice de la case à marquer comme visitée
MarqueVisite:

    # Prologue
    subu $sp $sp 12
    sw $a1 8($sp)
    sw $a2 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    add $a1 $a0 $a1         # Adresse de l'élément à modifier
    lb $a2 0($a1)           # Récupération de la valeur actuelle de la case
    lw $a1 8($sp)           # Récupération de la valeur originale de $a1
    addiu $a2 $a2 128
    jal ModifieTableau

    # Epilogue
    lw $a2 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 12

    jr $ra


# Permet voir si une case a été visitée ou non
## Entrées : $a0 : adresse du premier élément du tableau
##           $a1 : indice de la case à marquer comme visitée
## Sortie :  $v0 (=1 si visitée, =0 sinon)
TesteVisite:

    # Prologue
    subu $sp $sp 12
    sw $a0 8($sp)
    sw $a1 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    add $a1 $a0 $a1             # Adresse de la case à tester
    lb $a0 0($a1)               # Valeur de la case à tester
    li $v0 0                    # On dit par défaut que la case n'a pas été visitée
    bge $a0 $0 FinTesteVisite   # Si la valeur de la case est effectivement positive, on a fini
    li $v0 1                    # Sinon c'est que la case a été visitée

    # Epilogue
    FinTesteVisite:
    lw $a0 8($sp)
    lw $a1 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 12

    jr $ra


# Résolution d'un labyrinthe
ResoudreLabyrinthe:

    jal ImporterTableauDepuisFichier

    # On ajoute l'extension '.resolu'
    la $a0 fichier
    la $a1 ExtResolu
    jal Concatener

    # On récupère les sorties de ImporterTableauDepuisFichier appelé précédemment
    move $a0 $v0                # Nombre de lignes/colonnes du labyrinthe : N
    move $a1 $v1                # Adresse du premier élément du tableau

    jal ResolutionLabyrinthe
    jal SauvegarderTableau      # On écrit le contenu du tableau dans le fichier de sortie

    j Exit


# Fonction qui résoud le labyrinthe
# Entrées : $a0 = N
#           $a1 = adresse du premier élément du tableau
ResolutionLabyrinthe:

    # Prologue
    subu $sp $sp 16
    sw $a0 12($sp)
    sw $a1 8($sp)
    sw $s0 4($sp)
    sw $ra 0($sp)

    move $t0 $a0
    move $a0 $a1                # Adresse du premier élément du tableau
    move $a1 $t0                # N

    jal TrouverCaseFin
    move $s4 $v0                # On sauvegarde l'indice de la case de fin dans $s4

    jal TrouverCaseDepart
    move $a2 $a1                # N
    move $a1 $v0                # Indice de la case de départ
    jal MarqueVisite            # Marque la case courante comme visitée

    li $s2 0                    # Compteur

    # On se déplace dans le labyrinthe
    DeplaceLaby:
    jal VoisinResolution
    move $a1 $v0
    jal MarqueVisite            # Marque la case courante comme visitée
    beq $a1 -1 MarcheArriereR   # Si on est coincé, on dépile
    beq $a1 $s4 MarqueCheminSolution  # Si on tombe sur la case de fin, alors on sort de la boucle
    subu $sp $sp 4              # On réserve de la place sur la pile pour une case
    sw $a1 0($sp)               # On y stocke l'indice
    addi $s2 $s2 4              # On incrémente le compteur de 4
    j DeplaceLaby

    # Pour reculer si jamais on se retrouve bloqué
    MarcheArriereR:
    addu $sp $sp 4              # Case bloquée, on dépile
    subi $s2 $s2 4              # On décrémente le compteur
    beq $a1 $s4 MarqueCheminSolution  # Si on est à la fin, alors on sort de la boucle
    lw $a1 0($sp)               # Sinon on charge la valeur de la case précédente
    j DeplaceLaby               # ...et on retourne dans la boucle

    # Permet de marquer le chemin empilé comme chemin solution
    MarqueCheminSolution:
    beqz $s2 FinResolutionLabyrinthe # Si le compteur est à 0, on a fini
    lw $t6 0($sp)               # On récupère l'indice de la case courante
    addu $t6 $a0 $t6            # Adresse de la case courante
    lb $t7 0($t6)               # On récupère la valeur de la case
    addi $t7 $t7 64             # On marque la case comme faisant parti du "chemin solution"
    sb $t7 0($t6)               # On met à jour la valeur de la case
    subi $s2 $s2 4              # On décrémente le compteur
    addu $sp $sp 4              # On libère la place sur la pile
    j MarqueCheminSolution

    FinResolutionLabyrinthe:
    mul $a1 $a2 $a2             # $a1 = taille tu tableau (N*N)
    jal EnleverViste

    # Epilogue
    lw $a0 12($sp)
    lw $a1 8($sp)
    lw $s0 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 16

    jr $ra


# Permet de savoir si il y a un mur à un endroit spécifique
# Entrées : $a0 = Adresse du premier élément du tableau
#           $a1 = Indice de la case à tester
#           $a2 = Nombre qui détermine à quel endroit tester (1: mur en haut, 2: mur à droite, 4: mur en bas, 8: mur à gauche)
# Sortie :  $v0 = 1 si mur, 0 si pas de murs
TestMur:

    # Prologue
    subu $sp $sp 8
    sw $s0 4($sp)
    sw $s1 0($sp)

    # Corps de la fonction
    add $s0 $a0 $a1             # Adresse de la case à tester
    lb $s1 0($s0)               # $s1 : valeur de la case
    and $v0 $a2 $s1             # On vérifie la présence du bit de mur en question
    beqz $v0 FinTestMur         # Si pas de mur on retourne $v0=0
    li $v0 1                    # Sinon $v0=1

    # Epilogue
    FinTestMur:
    lw $s0 4($sp)
    lw $s1 0($sp)
    addu $sp $sp 8

    jr $ra


# Retourne l'indice d'un des voisins
## Entrée : $a0 : adresse du premier élément du tableau contenant le labyrinthe
##          $a1 : indice X de la case courante
##          $a2 : valeur de N
## Sortie : $v0 : l'indice d'un des voisins choisis aléatoirement (vaut -1 si aucun voisin)
VoisinResolution:

    # Prologue
    subu $sp $sp 32
    sw $a0 28($sp)
    sw $a1 24($sp)
    sw $a2 20($sp)
    sw $a3 16($sp)
    sw $s0 12($sp)
    sw $s1 8($sp)
    sw $s2 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    li $s0 0                        # Compteur du nombre de voisins initialisé à 0
    move $t0 $a1                    # X
    move $t1 $a2                    # N
    div $t2 $t0 $t1
    mfhi $t2                        # X%N

    # Valeurs pour les tests
    subi $t3 $t1 1                  # $t3=N-1
    mul $t4 $t1 $t3                 # $t4=N*(N-1)

    # On cherche les différents voisins disponibles
    beq $t2 0 FinVoisinRGauche      # Si X%N = 0 alors pas de voisin à gauche
    subi $a1 $t0 1                  # Sinon l'indice vaut X-1
    jal TesteVisite                 # On vérifie si la case a déjà été visitée
    beq $v0 1 FinVoisinRGauche      # Si c'est le cas, ce voisin n'est plus disponible

    # On vérifie la présence d'un mur; si c'est le cas cette case ne peut être la prochaine case
    li $a2 2
    jal TestMur
    bnez $v0 FinVoisinRGauche

    addi $s0 $s0 4                  # On incremente le compteur de 4
    subu $sp $sp 4                  # On fait de la place sur la pile pour stocker l'indice de ce voisin
    sw $a1 0($sp)                   # On sauvegarde l'indice du voisin trouvé sur la pile
    FinVoisinRGauche:

    beq $t3 $t2 FinVoisinRDroite    # Si X%N = N-1 alors pas de voisin à droite
    addi $a1 $t0 1                  # Sinon l'indice vaut X+1
    jal TesteVisite                 # On vérifie si la case a déjà été visitée
    beq $v0 1 FinVoisinRDroite      # Si c'est le cas, ce voisin n'est plus disponible

    # On vérifie la présence d'un mur; si c'est le cas cette case ne peut être la prochaine case
    li $a2 8
    jal TestMur
    bnez $v0 FinVoisinRDroite

    addi $s0 $s0 4                  # On incremente le compteur de 4
    subu $sp $sp 4                  # On fait de la place sur la pile pour stocker l'indice de ce voisin
    sw $a1 0($sp)                   # On sauvegarde l'indice du voisin trouvé sur la pile
    FinVoisinRDroite:

    blt $t0 $t1 FinVoisinRHaut      # Si X<N alors il n'y a pas de voisin en haut
    sub $a1 $t0 $t1                 # Sinon l'indice vaut X-N
    jal TesteVisite                 # On vérifie si la case a déjà été visitée
    beq $v0 1 FinVoisinRHaut        # Si c'est le cas, ce voisin n'est plus disponible

    # On vérifie la présence d'un mur; si c'est le cas cette case ne peut être la prochaine case
    li $a2 4
    jal TestMur
    bnez $v0 FinVoisinRHaut

    addi $s0 $s0 4                  # On incremente le compteur de 8
    subu $sp $sp 4                  # On fait de la place sur la pile pour stocker l'indice de ce voisin
    sw $a1 0($sp)                   # On sauvegarde l'indice du voisin trouvé sur la pile
    FinVoisinRHaut:

    bge $t0 $t4 FinVoisinRBas       # Si X >= N*(N-1) alors il n'y a pas de voisin en bas
    add $a1 $t0 $t1                 # Sinon l'infice vaut X+N
    jal TesteVisite                 # On vérifie si la case a déjà été visitée
    beq $v0 1 FinVoisinRBas         # Si c'est le cas, ce voisin n'est plus disponible

    # On vérifie la présence d'un mur; si c'est le cas cette case ne peut être la prochaine case
    li $a2 1
    jal TestMur
    bnez $v0 FinVoisinRBas

    addi $s0 $s0 4                  # On incremente le compteur de 4
    subu $sp $sp 4                  # On fait de la place sur la pile pour stocker l'indice de ce voisin
    sw $a1 0($sp)                   # On sauvegarde l'indice du voisin trouvé sur la pile
    FinVoisinRBas:

    li $v0 -1                       # Valeur de retour par défaut

    div $s1 $s0 4                   # On récupère le nombre de voisins ajoutés sur la pile
    beq $s1 $0 FinVoisinR           # Si aucun voisin n'a été trouvé, on a pas besoin de faire ce qui suit

    li $a0 0
    move $a1 $s1                    # Borne sup = $s1
    li $v0 42                       # Génère un nombre aléatoire dans $a0, 0 <= $a0 < $a1
    syscall
    move $s2 $a0
    mul $s2 $s2 4                   # On calcule l'offset pour récupérer le bon voisin
    addu $s2 $sp $s2                # On récupère la bonne adresse sur la pile
    lw $v0 0($s2)                   # $v0 contient désormais l'indice d'un voisin choisi aléatoirement

    addu $sp $sp $s0                # On libère la place sur la pile

    # épilogue
    FinVoisinR:
    lw $a0 28($sp)
    lw $a1 24($sp)
    lw $a2 20($sp)
    lw $a3 16($sp)
    lw $s0 12($sp)
    lw $s1 8($sp)
    lw $s2 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 32

    jr $ra


# Créer un tableau avec les données provenant d'un fichier
## Sorties : $v0 = le nombre N de ligne/colonnes du labyrinthe importé
##           $v1 = adresse du premier élément du tableau
ImporterTableauDepuisFichier:

    # Prologue
    subu $sp $sp 28
    sw $a0 24($sp)
    sw $a1 20($sp)
    sw $a2 16($sp)
    sw $s0 12($sp)
    sw $s1 8($sp)
    sw $s2 4($sp)
    sw $s3 0($sp)

    # Ouvrir le fichier
    la $a0 fichier      # Nom du fichier
    li $a1 0            # Ouverture du fichier en lecture (0 : lecture; 1 écriture, ...)
    li $a2 0            # Pas besoin de mode (ignoré)
    li $v0 13           # Appel système pour ouvrir un fichier
    syscall
    blt $v0 $0 ErreurFichierNonTrouve  # Le fichier n'existe pas, on relance le programme depuis le début
    move $s0 $v0        # Sauvegarde du descripteur du fichier

    # Lecture du fichier
    move $a0 $s0        # Descripteur du fichier
    la $a1 buffer       # Adresse du buffer dans lequel on doit écrire
    li $a2 1            # Taille du buffer = 1
    li $v0 14           # Appel système pour lire un fichier
    syscall

    lb $s1 0($a1)       # Premier digit
    subiu $s1 $s1 0x30  # On le convertit en entier
    mul $s1 $s1 10      # On le multiplie par 10, car c'est le chiffre des dizaine

    li $v0 14           # Appel système pour lire un fichier
    syscall

    lb $s2 0($a1)       # Deuxième digit
    subiu $s2 $s2 0x30  # On le converti en entier

    addu $t2 $s1 $s2    # $t2 contient la valeur de N

    mul $a0 $t2 $t2     # Taille du tableau à créer en octets (N*N octets)
    li $v0 9            # On réserve de la place pour le tableau
    syscall             # $v0 contiendra donc l'adresse du premier élément du tableau

    move $v1 $v0        # Adresse du premier élément du tableau
    move $t0 $v1        # On met aussi cette valeur dans $t0
    addu $t1 $t0 $a0    # Adresse de fin du tableau

    # On parcourt chaque caractère du fichier
    BoucleImporterTableau:
    beq $t0 $t1 FinBoucleImporterTableau

    move $a0 $s0        # Descripteur du fichier
    la $a1 buffer       # Adresse du buffer à partir duquel on doit écrire
    li $a2 1            # Taille du buffer = 1
    li $v0 14           # Appel système pour lire un fichier
    syscall

    lb $s1 0($a1)       # Caractère courant

    # Si le caractère courant n'est pas un chiffre on recommence
    blt $s1 48 BoucleImporterTableau
    bgt $s1 57 BoucleImporterTableau

    subiu $s1 $s1 0x30  # On converti le premier digit en entier
    mul $s1 $s1 10      # On le multiplie par 10, car c'est le chiffre des dizaine

    li $v0 14           # Appel système pour lire un fichier
    syscall

    lb $s2 0($a1)       # Second digit
    subiu $s1 $s1 0x30  # On le converti en entier

    addu $s3 $s1 $s2    # $s3 : entier de la case
    sb $s3 0($t0)       # On sauvegarde la valeur dans la bonne case du tableau

    addiu $t0 $t0 1     # On incrémente $t0
    j BoucleImporterTableau

    # On ferme le fichier
    FinBoucleImporterTableau:
    move $a0 $s0        # Descripteur du fichier à fermer
    li $v0 16           # Appel système pour fermer un fichier
    syscall

    move $v0 $t2        # $v0 = N

    # Epilogue
    lw $a0 24($sp)
    lw $a1 20($sp)
    lw $a2 16($sp)
    lw $s0 12($sp)
    lw $s1 8($sp)
    lw $s2 4($sp)
    lw $s3 0($sp)
    addu $sp $sp 28

    jr $ra


# Fonction qui permet de relancer le programme si le fichier entré est inexistant (pour la résolution)
ErreurFichierNonTrouve:

    li $v0 4                            # On dit que l'on va faire des appels systèmes pour afficher des chaines de caractères
    la $a0 TexteErreurFichier404        # On charge le début de la chaine de caractère pour le message d'erreur
    syscall                             # Et on l'affiche
    la $a0 fichier                      # On charge le nom de fichier entré par l'utilisateur
    move $t1 $a0                        # On sauvegarde la valeur de l'adresse du buffer 'fichier' pour plus tard
    syscall                             # On affiche le nom du fichier inexistant
    la $a0 TexteErreurFichier404Fin     # On charge la fin de la chaine de caractères pour le message d'erreur
    syscall                             # Et on l'affiche

    # On met des '0' partout tout au long du buffer
    li $t0 1024                         # Taille réservé pour stocker un nom de fichier dans 'fichier'
    ResetFichierBuffer:                 # Boucle permettant de mettre des '0' partout
    subiu $t0 $t0 1                     # On décrémente notre compteur de nombre de '0' restants à insérer
    addu $t2 $t0 $t1                    # On récupère la bonne adresse pour la case courante
    sb $0 0($t2)                        # On met un '0' dans la case courante
    beqz $t0 __start                    # Une fois que le buffer est nettoyé, on relance le programme à partir du début
    j ResetFichierBuffer                # Sinon on continu le nettoyage


# Fonction qui permet de trouver la case de départ
## Entrées : $a0 = adresse du premier élément du tableau
##           $a1 = N
## Sortie:   $v0 = adresse de la case de départ
TrouverCaseDepart:

    # Prologue
    subu $sp $sp 12
    sw $a0 8($sp)
    sw $a1 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    move $s2 $a0            # $s2 : adresse du premier élement du tableau

    li $t0 16               # Masque pour trouver le bit de départ
    lb $s0 0($a0)           # On récupère la valeur de la case dans $s0

    mul $s1 $a1 $a1
    add $s1 $a0 $s1         # $s1 : l'adresse de la case de fin

    CaseSuivante:
    and $v0 $s0 $t0         # On teste si il y a un bit en B4
    addi $a0 $a0 1          # On incrémente $a0, qui contient l'adresse de la case courante
    bnez $v0 FinCaseDepart  # Sinon on a trouvé la case de départ
    beq $a0 $s1 FinCaseDepart
    lb $s0 0($a0)           # On charge la nouvelle valeur
    j CaseSuivante
    FinCaseDepart:

    subu $a0 $a0 $s2        # Adresse finale - adresse initiale
    subi $a0 $a0 1          # On enlève 1, car on a commencé à traiter la première case avant
    move $v0 $a0            # On met le bon indice sur la valeur de sortie, $v0

    # Epilogue
    lw $a0 8($sp)
    lw $a1 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 12

    jr $ra


# Fonction qui permet de trouver la case de fin
## Entrées : $a0 = adresse du premier élément du tableau
##           $a1 = N
## Sortie:   $v0 = adresse de la case de fin
TrouverCaseFin:

    # Prologue
    subu $sp $sp 12
    sw $a0 8($sp)
    sw $a1 4($sp)
    sw $ra 0($sp)

    # Corps de la fonction
    move $s2 $a0            # $s2 : adresse du premier élement du tableau

    li $t0 32               # Masque pour trouver le bit de fin
    lb $s0 0($a0)           # On récupère la valeur de la case dans $s0

    mul $s1 $a1 $a1
    add $s1 $a0 $s1         # $s1 : l'adresse de la case de fin

    CaseSuivanteFin:
    and $v0 $s0 $t0         # On teste si il y a un bit en B5
    addi $a0 $a0 1
    bnez $v0 FinCaseDepartFin # Sinon on a trouvé la case de fin
    beq $a0 $s1 FinCaseDepartFin
    lb $s0 0($a0)           # On charge la nouvelle valeur
    j CaseSuivanteFin
    FinCaseDepartFin:

    subu $a0 $a0 $s2    # Adresse finale - adresse initiale
    subi $a0 $a0 1      # On enlève 1, car on a commencé à traiter la première case avant
    move $v0 $a0        # On met le bon indice sur la valeur de sortie, $v0

    # Epilogue
    lw $a0 8($sp)
    lw $a1 4($sp)
    lw $ra 0($sp)
    addu $sp $sp 12

    jr $ra


# Fin du programme
Exit:
    li $v0 10
    syscall
