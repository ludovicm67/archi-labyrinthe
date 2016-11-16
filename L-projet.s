.data
displayMenu:	.asciiz "\nMENU :\n 1 - Génération d'un labyrinthe\n 2 - Résolution d'un labyrinthe\n\nEntrez votre choix : "
Demande: 	.asciiz "Veuillez entrer un entier supérieur ou égal à 2 : "

fichier: 	.asciiz "./azeaze.txt"
buffer:		.asciiz "Hello world ! =D"


.text
.globl __start

# Point d'entrée du programme
__start:


# Ouvrir le fichier
la $a0 fichier # nom du fichier
li $a1 1 # on ouvre le fichier en écriture (0 : lecture; 1 écriture)
li $a2 0 # pas besoin de mode (ignoré)
li $v0 13 # appel système pour ouvrir un fichier
move $s6 $v0 # sauvegarde la description du fichier

# Ecrire dans le fichier
move $a0 $s6 # description du fichier
la $a1 buffer # on écrit 
li $v0 15 # appel système pour écrire dans un fichier



# Test de printDigits
li $a0 5
jal PrintDigits


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


# Affiche un nombre entier sur 2 digits
## $a0 = le nombre à afficher
PrintDigits:
move $t8 $a0
li $t9 9
bgt $a0 $t9 FinPrintDigits
li $a0 0
li $v0 1
syscall

FinPrintDigits:
move $a0 $t8
li $v0 1
syscall

jr $ra


#Résolution d'un labyrinthe
resoudreLabyrinthe:
## à compléter
j Exit

# Fin du programme
Exit:
li $v0 10 
syscall
