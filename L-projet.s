.data

TexteMenu:
	.asciiz "\nMENU :\n 1 - Génération d'un labyrinthe\n 2 - Résolution d'un labyrinthe\n\nEntrez votre choix : "
	
TexteDemanderN:
	.asciiz "Veuillez entrer un entier N compris entre 2 et 99 : "
	
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
	li $t1 1			# On met t1 à 1
	li $t2 2			# On met t2 à 2
	beq $v0 $t1 genereLabyrinthe	# Choix 1 - Générer un labyrinthe
	beq $v0 $t2 resoudreLabyrinthe	# Choix 2 - Résoudre un labyrinthe
	j Menu				# Choix de l'utilisateur inexistant -> on lui redemande

# Génération d'un labyrinthe
genereLabyrinthe:

	# Pour vérifier si N est bien compris entre 2 et 99
	li $t2 2 			# On attribue la valeur 2 à $t2
	li $t9 99			# On attribue la valeur 99 à $t9
	
	# On demande la taille N du labyrinthe à l'utilisateur
	DemanderN: 
	la $a0 TexteDemanderN 		# Chargement de la chaîne de caractère TexteDemanderN dans $a0
	li $v0 4 			# Affichage de la chaîne TexteDemanderN
	syscall 			# Appel système
	li $v0 5 			# On lit l'entier que l'utilisateur a entré
	syscall
	move $a0 $v0 			# On déplace la valeur que l'utilisateur a entré dans $a0
	blt $a0 $t2 DemanderN 		# On teste si $a0<2 si c'est vrai on recommence à DemanderN
	bgt $a0 $t9 DemanderN 		# On teste si $a0>99 si c'est vrai on recommence à DemanderN
	
	move $a1 $a0 			# On deplace la valeur que l'utilisateur a rentré dans $a1
	mul $a0 $a1 $a1			# Taille du tableau à créer (N*N)
	#jal CreerTableau
	
	
	# Juste pour tester l'écriture du nombre de ligne/colonnes (N) dans la première ligne du fichier (à enlever par la suite)
	jal VideFichier
	move $a0 $a1
	jal GetDigits
	li $a0 2 # nombre d'arguments (soit 1, soit 2)
	addiu $a1 $v0 0x30 # On met le premier digit retourné dans a1, en le convertissant en caractère
	addiu $a2 $v1 0x30 # On met le second digit retourné dans a2, en le convertissant en caractère

	jal EcrireDansFichier
	
	
	# fin du test
	
	
	j Exit



# Retourne un nombre entier sur 2 digits
## Entrée : $a0 = le nombre à afficher
## Sortie : $v0 = le premier digit du nombre
##          $v1 = le second digit du nombre
GetDigits:

	li $v0 0 			# par défaut le premier digit vaut 0
	move $v1 $a0 			# on met par défaut v1 à la valeur de a0
	li $t0 10			# t9 contient la valeur 9 (pour le test suivant)
	ble $a0 $t0 FinGetDigits	# Si $a0 < 10, alors on a fini
	
	# Si le nombre est supérieur ou égal à 10, ont doit changer les valeurs de sortie
	div $t1 $a0 $t0
	move $v0 $t1
	mfhi $v1
	
	FinGetDigits:
	jr $ra


# Ecrire des caractères dans un fichier
## a0 = nombre d'arguments (soit 1, soit 2)
## a1 = premier caractère
## a2 = deuxième caractère (si a0 = 2)
EcrireDansFichier:
	# epilogue
	subu $sp $sp 20
	sw $a0 16($sp)
	sw $a1 12($sp)
	sw $a2 8($sp)
	sw $s1 4($sp)
	sw $ra 0($sp)

	# Ouvrir le fichier
	la $a0 fichier 		# nom du fichier
	li $a1 9 		# on ouvre le fichier en écriture (0 : lecture; 1 écriture, ... 9 : écriture à la fin)
	li $a2 0 		# pas besoin de mode (ignoré)
	li $v0 13 		# appel système pour ouvrir un fichier
	syscall
	move $s1 $v0 		# sauvegarde du descripteur du fichier

	# Ecrire dans le fichier
	## écriture du premier caractère
	move $a0 $s1 		# descripteur du fichier
	la $a1 buffer 		# adresse du buffer à partir duquel on doit écrire
	lw $t1 12($sp) 		# premier caractère à écrire
	sb $t1 ($a1)		# on place notre caractère dans le buffer
	li $a2 1 		# Taille du buffer = 1 (on écrit caractère par caractère)
	li $v0 15 		# appel système pour écrire dans un fichier
	syscall
	
	li $t2 2		# On met $t2 à la valeur 2
	lw $t0 16($sp)		# On met $t0 à la valeur originale de $a0
	bne $t0 $t2 FermerFichier	# Si on ne souhaitais pas afficher 2 caractères, on ferme directement le fichier
	lw $t2 8($sp) 		# deuxième caractère à écrire
	sb $t2 ($a1)		# on place notre caractère dans le buffer
	li $v0 15 		# appel système pour écrire dans un fichier
	syscall
	

	# On ferme le fichier
	FermerFichier:
	move $a0 $s1 		# descripteur du fichier à fermer
	li $v0 16 		# appel système pour fermer un fichier
	syscall


	# epilogue
	lw $a0 16($sp)
	lw $a1 12($sp)
	lw $a2 8($sp)
	lw $s1 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 20
	
	jr $ra



# Vide le fichier
VideFichier:
	# epilogue
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

