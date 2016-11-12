.data
displayMenu: .asciiz "MENU :\n 1 - Génération d'un labyrinthe\n 2 - Résolution d'un labyrinthe\n\nEntrez votre choix : "


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
j Menu				# Choix de l'utilisateur inexistant; on lui redemande

# Génération d'un labyrinthe
genereLabyrinthe:
## à compléter
j Exit

#Résolution d'un labyrinthe
resoudreLabyrinthe:
## à compléter
j Exit

# Fin du programme
Exit:
li $v0 10
syscall
