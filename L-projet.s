.data
displayMenu:	.asciiz "\nMENU :\n 1 - Génération d'un labyrinthe\n 2 - Résolution d'un labyrinthe\n\nEntrez votre choix : "
Demande: 	.asciiz "Veuillez entrer un entier supérieur ou égal à 2 : "

fichier: 	.asciiz "azeaze.txt"
buffer:		.asciiz "Hello world ! =D"


.text
.globl __start

# Point d'entrée du programme
__start:


# Test d'écriture dans un fichier
li $a0 1
jal GetDigits
li $a0 2 # nombre d'arguments (soit 1, soit 2)
addiu $a1 $v0 0x30 # On met le premier digit retourné dans a1, en le convertissant en caractère
addiu $a2 $v1 0x30 # On met le second digit retourné dans a2, en le convertissant en caractère

#debug (à virer !!!) : juste pour vérifier la sortie de GetDigits
li $v0 11 # pour les appels systèmes (affichages d'un caractère)
move $a0 $a1
syscall
move $a0 $a2
syscall

jal EcrireDansFichier



# Affichage du menu
Menu:
la $a0 displayMenu		# On charge l'adresse de displayMenu dans $a0
li $v0 4			# On dit que l'on souhaite afficher une chaîne de caractère
syscall				# On effectue l'appel système
li $v0 5			# On demande à l'utilisateur de saisir un entier (sera stocké dans $v0)
syscall				# On effectue l'appel système
li $t1 1			# On met t1 = 1
li $t2 2			# On met t2 = 2
beq $v0 $t1 genereLabyrinthe	# Choix 1 - Générer un labyrinthe
beq $v0 $t2 resoudreLabyrinthe	# Choix 2 - Résoudre un labyrinthe
j Menu				# Choix de l'utilisateur inexistant -> on lui redemande

# Génération d'un labyrinthe
genereLabyrinthe:

# Affichage de la demande à l'utilisateur
Affichage:
la $a0 Demande 			# Chargement de la chaîne de caractère Demande dans $a0
li $v0 4 			# Affichage de la chaîne Demande
syscall 			# Appel système
li $v0 5 			# On lit l'entier que l'utilisateur a entré
syscall
move $a0 $v0 			# On déplace la valeur que l'utilisateur a entré dans $v0
li $t2 2 			# On attribue la valeur 2 à $v1
blt $v0 $t2 Affichage		# On teste si $v0<2 si c'est vrai on recommence à Affichage
li $v0 1 			
syscall				# sinon on affiche $a0
j Exit				# Le programme est fini


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
	move $a0 $s1 		# descripteur du fichier
	la $a1 buffer 		# adresse du buffer à partir duquel on doit écrire
	lw $a2 16($sp) 		# Taille du buffer (qui a été passé en argument dans $a0)
	li $v0 15 		# appel système pour écrire dans un fichier
	syscall

	# On ferme le fichier
	move $a0 $s1 		# descripteur du fichier à fermer
	li $v0 16 		# appel système pour fermer un fichier
	syscall


	# epilogue
	subu $sp $sp 20
	sw $a0 16($sp)
	sw $a1 12($sp)
	sw $a2 8($sp)
	sw $s1 4($sp)
	sw $ra 0($sp)
	jr $ra




#Résolution d'un labyrinthe
resoudreLabyrinthe:
## à compléter
j Exit

# Fin du programme
Exit:
li $v0 10 
syscall

