.data

TexteMenu:
	.asciiz "\nMENU :\n 1 - Génération d'un labyrinthe\n 2 - Résolution d'un labyrinthe\n\nEntrez votre choix : "
	
TexteDemanderN:
	.asciiz "Veuillez entrer un entier N compris entre 2 et 99 : "
	
RetChar:
	.asciiz "\n"
	
Espace:
	.asciiz " "
	
fichier:
	.asciiz "azeaze.txt"
	
buffer:
	.space 1 # on initialise un buffer de taille 1


.text
.globl __start

# Point d'entrée du programme
__start:


# Affichage du menu
Menu:
	la $a0 TexteMenu		# On charge l'adresse de displayMenu dans $a0
	li $v0 4			# On dit que l'on souhaite afficher une chaîne de caractère
	syscall				# On effectue l'appel système
	li $v0 5			# On demande à l'utilisateur de saisir un entier (sera stocké dans $v0)
	syscall				# On effectue l'appel système
	beq $v0 1 genereLabyrinthe	# Choix 1 - Générer un labyrinthe
	beq $v0 2 resoudreLabyrinthe	# Choix 2 - Résoudre un labyrinthe
	j Menu				# Choix de l'utilisateur inexistant -> on lui redemande



# Génération d'un labyrinthe
genereLabyrinthe:
	
	# On demande la taille N du labyrinthe à l'utilisateur
	DemanderN: 
	la $a0 TexteDemanderN 		# Chargement de la chaîne de caractère TexteDemanderN dans $a0
	li $v0 4 			# Affichage de la chaîne TexteDemanderN
	syscall 			# Appel système
	li $v0 5 			# On lit l'entier que l'utilisateur a entré
	syscall
	move $a0 $v0 			# On déplace la valeur que l'utilisateur a entré dans $a0
	blt $a0 2 DemanderN 		# On teste si $a0<2 si c'est vrai on recommence à DemanderN
	bgt $a0 99 DemanderN 		# On teste si $a0>99 si c'est vrai on recommence à DemanderN
	
	move $a2 $a0 			# On deplace la valeur que l'utilisateur a rentré dans $a2
	mul $a0 $a2 $a2			# Taille du tableau à créer (N*N)
	jal CreerTableau		# $v0 contiendra l'adresse du premier élément du tableau
	
	move $a0 $a2			# On met $a0 à la valeur entrée par l'utilisateur, qui a été stockée dans $a2
	move $a1 $v0			# on fait en sorte que $a1 contienne l'adresse du premier élément du tableau
	jal AfficheTableau
	
	
	# Juste pour tester l'écriture du nombre de ligne/colonnes (N) dans la première ligne du fichier (à enlever par la suite)
	jal VideFichier
	move $a0 $a2
	jal GetDigits
	li $a0 2 # nombre d'arguments (soit 1, soit 2)
	move $a1 $v0 # premier digit
	move $a2 $v1 # deuxième digit

	jal EcrireDansFichier
	# fin du test
	
	
	j Exit



# Permet de créer un tableau pour stocker le labyrinthe, avec par défaut des murs partout pour chaque case (case de valeur 15)
## Entrée : $a0 = taille du tableau
## Sortie : $v0 = adresse du premier élément du tableau
CreerTableau:
	# prologue
	subu $sp $sp 8
	sw $a0 4($sp)
	sw $ra 0($sp)
	
	# corps de la fonction
	li $t0 0		# compteur pour la boucle
	li $t5 15		# valeur pour remplir le tableau
	
	mul $a0 $a0 4		# taille du tableau à créer en octets
	li $v0 9		# on récupère l'adresse du premier élément du tableau
	syscall			# $v0 contiendra donc l'adresse du premier élément du tableau
	
	BoucleCreerTableau:
	beq $t0 $a0 FinBoucleTableauCreer	# si $t0=$a0 ($t0:compteur, $a0: taille en octets) alors c'est qu'on a remplit le tableau
	addu $t1 $v0 $t0			# sinon on ajoute la valeur du compteur à l'adresse pour se déplacer dans le tableau et on met ça dans $t1
	sw $t5 0($t1)				# on remplit la case courante du tableau (à l'adresse $t1) avec 15 (la valeur de $t5)
	addu $t0 $t0 4				# on incrémente le compteur de 4
	j BoucleCreerTableau			# on recommence (:
	
	# epilogue
	FinBoucleTableauCreer:
	lw $a0 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 8
	
	jr $ra



# Permet d'afficher le contenu d'un tableau carré (N*N)
## Entrée : $a0 = N, le nombre de lignes/colonnes (prec : $a0>=0)
##          $a1 = adresse du premier élément du tableau
AfficheTableau:
	# prologue
	subu $sp $sp 16
	sw $s0 12($sp)
	sw $a0 8($sp)
	sw $a1 4($sp)
	sw $ra 0($sp)
	
	
	# corps de la fonction
	move $s0 $a0		# $s0 : nombre de cases par ligne/colonne
	mul $t0 $a0 $a0		# $t0 : nombre total de cases
	mul $t0 $t0 4		# $t0 : taille du tableau en octets
	move $t1 $s0		# $t1 : ième colonne (initialisé à N, dans le but de commencer par un saut de ligne)
	li $t2 0 		# $t2 : offset de la case courante du tableau
	
	li $v0 1
	syscall
	
	BoucleAfficheTableau:
	beq $t2 $t0 FinBoucleAfficheTableau	# Si on a parcouru toutes les cases du tableau, on sort de la boucle
	
	# On traite ici le cas du saut de ligne
	blt $t1 $s0 ApresSautDeLigne		# Si on est pas encore en fin de ligne, on ne saute pas de ligne
	li $t1 0				# On est à nouveau dans la 0ème colonne
	la $a0 RetChar				# On charge l'adresse de RetChar dans $a0
	li $v0 4				# On dit qu'on souhaite afficher la chaine de caractères stockée dans $a0
	syscall					# On effectue l'appel système

	# On traite ici le cas des espaces entre les nombres	
	ApresSautDeLigne:
	beq $t1 0 ApresEspace			# Si on est en début de ligne, pas besoin d'insérer d'espace
	la $a0 Espace				# On charge l'adresse de Espace dans $a0
	li $v0 4				# On dit qu'on souhaite afficher la chaine de caractères stockée dans $a0
	syscall					# On effectue l'appel système
	
	ApresEspace:
	addu $t3 $a1 $t2			# $t3 : adresse de la case courante
	
	# AfficheEntier
	lw $a0 0($t3)				# $a0 contient désormais la valeur de la case courante
	li $v0 1				# on dit que l'on souhaite afficher un entier ($a0)
	syscall					# on effectue l'appel système
	
	addu $t2 $t2 4				# on incrémente $t2 de 4 (on avance d'une case du tableau, l'offset augmente donc de 4)
	addu $t1 $t1 1				# on incrémente $t1 de 1 (on avance d'une colonne)
	
	j BoucleAfficheTableau
	
	
	# prologue
	FinBoucleAfficheTableau:
	lw $s0 12($sp)
	lw $a0 8($sp)
	lw $a1 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 16
	
	jr $ra



# Retourne un nombre entier sur 2 digits (convertis en caractères)
## Entrée : $a0 = le nombre à retourner sous forme de 2 digits (prec : 0 <= $a0 <= 99)
## Sortie : $v0 = le premier digit du nombre, sous forme de caractère
##          $v1 = le second digit du nombre, sous forme de caractère
GetDigits:
	li $v0 0 			# par défaut le premier digit vaut 0
	move $v1 $a0 			# on met par défaut v1 à la valeur de a0
	ble $a0 10 FinGetDigits		# Si $a0 <= 10, alors on a fini
	
	# Si le nombre est supérieur ou égal à 10, ont doit changer les valeurs de sortie
	div $v0 $a0 10			# Le premier digit est donc le résultat de la division entière de $a0 par 10
	mfhi $v1			# ...et le deuxième digit est le résultat de $a0 mod 10
					# (stocké dans hi lors de div, que l'on récupère avec mfhi)
	
	FinGetDigits:
	# On convertit les digis en caractères, en ajoutant 0x30
	addiu $v0 $v0 0x30 # On convertit le premier digit en caractère
	addiu $v1 $v1 0x30 # On convertit le second digit en caractère
	
	jr $ra


# Ecrire des caractères dans un fichier
## a0 = nombre d'arguments (soit 1, soit 2)
## a1 = premier caractère
## a2 = deuxième caractère (si a0 = 2)
EcrireDansFichier:
	# prologue
	subu $sp $sp 24
	sw $a0 20($sp)
	sw $a1 16($sp)
	sw $a2 12($sp)
	sw $s0 8($sp)
	sw $s1 4($sp)
	sw $ra 0($sp)

	# Ouvrir le fichier
	la $a0 fichier 		# nom du fichier
	li $a1 9 		# on ouvre le fichier en écriture (0 : lecture; 1 écriture, ... 9 : écriture à la fin)
	li $a2 0 		# pas besoin de mode (ignoré)
	li $v0 13 		# appel système pour ouvrir un fichier
	syscall
	move $s0 $v0 		# sauvegarde du descripteur du fichier

	# Ecrire dans le fichier
	## écriture du premier caractère
	move $a0 $s0 		# descripteur du fichier
	la $a1 buffer 		# adresse du buffer à partir duquel on doit écrire
	lw $s1 16($sp) 		# premier caractère à écrire
	sb $s1 ($a1)		# on place notre caractère dans le buffer
	li $a2 1 		# Taille du buffer = 1 (on écrit caractère par caractère)
	li $v0 15 		# appel système pour écrire dans un fichier
	syscall
	
	lw $s1 20($sp)		# On met $s1 à la valeur originale de $a0
	bne $s1 2 FermerFichier	# Si on ne souhaitais pas afficher 2 caractères, on ferme directement le fichier
	lw $s1 12($sp) 		# deuxième caractère à écrire
	sb $s1 ($a1)		# on place notre caractère dans le buffer
	li $v0 15 		# appel système pour écrire dans un fichier
	syscall
	

	# On ferme le fichier
	FermerFichier:
	move $a0 $s0 		# descripteur du fichier à fermer
	li $v0 16 		# appel système pour fermer un fichier
	syscall


	# epilogue
	lw $a0 20($sp)
	lw $a1 16($sp)
	lw $a2 12($sp)
	lw $s0 8($sp)
	lw $s1 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 24
	
	jr $ra



# Vide le fichier
VideFichier:
	# prologue
	subu $sp $sp 16
	sw $a0 12($sp)
	sw $a1 8($sp)
	sw $a2 4($sp)
	sw $ra 0($sp)

	# Ouvrir le fichier
	la $a0 fichier 		# nom du fichier
	li $a1 1 		# on ouvre le fichier en écriture (0 : lecture; 1 écriture, ... 9 : écriture à la fin)
	li $a2 0 		# pas besoin de mode (ignoré)
	li $v0 13 		# appel système pour ouvrir un fichier
	syscall
	
	# On ferme directement le fichier, ce qui aura pour effet de le vider
	move $a0 $v0 		# descripteur du fichier à fermer
	li $v0 16 		# appel système pour fermer un fichier
	syscall

	# epilogue
	lw $a0 12($sp)
	lw $a1 8($sp)
	lw $a2 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 16
	
	jr $ra




#Résolution d'un labyrinthe
resoudreLabyrinthe:
	## à compléter
	j Exit



# Fin du programme
Exit:
	li $v0 10 
	syscall

