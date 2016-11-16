.data
displayMenu: .asciiz "\nMENU :\n 1 - Génération d'un labyrinthe\n 2 - Résolution d'un labyrinthe\n\nEntrez votre choix : "
Demande: .asciiz "Veuillez entrer un entier supérieur ou égal à 2 : "


.text
.globl __start

# Point d'entrée du programme
__start:
j Menu				# Affichage du menu


# Affichage du menu
Menu:
la $a0 displayMenu		# On charge l'adresse de displayMenu dans $a0
li $v0 4			# On dit que l'on souhaite afficher une chaîne de caractère
syscall				# On effectue l'appel système
li $v0 5			# On demande à l'utilisateur de saisir un entier (sera stocké dans $v0)
syscall				# On effectue l'appel système
li $t1 1
li $t2 2
beq $v0 $t1 genereLabyrinthe	# Choix 1 - Générer un labyrinthe
beq $v0 $t2 resoudreLabyrinthe	# Choix 2 - Résoudre un labyrinthe
j Menu				# Choix de l'utilisateur inexistant -> on lui redemande

# Génération d'un labyrinthe
genereLabyrinthe:

j Affichage 			# Affichage de la demande à l'utilisateur

Affichage: 
la $a0 Demande 			# Chargement de la chaîne de caractère Demande dans $a0
li $v0 4 			# Affichage de la chaîne Demande
syscall 			# Appel système

li $v0 5 			# On lit l'entier que l'utilisateur a entré
syscall

j Generation 

Generation:
move $a0 $v0 			# On déplace la valeur que l'utilisateur a entré dans $v0
li $v1, 2 			# On attribue la valeur 2 à $v1
blt $v0, $v1, Affichage 	# On teste si $v0<2 si c'est vrai on recommence à Affichage
li $v0 1 			# sinon on affiche $v0
syscall
j Exit				# Le programme est fini

#Résolution d'un labyrinthe
resoudreLabyrinthe:
## à compléter
j Exit

# Fin du programme
Exit:
li $v0 10 
syscall
