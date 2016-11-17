.data
displayMenu: .asciiz "\nMENU :\n 1 - Génération d'un labyrinthe\n 2 - Résolution d'un labyrinthe\n\nEntrez votre choix : "
Demande: .asciiz "Veuillez entrer un entier supérieur ou égal à 2 : "
Tableau: .asciiz "Tableau de taille: "
Aladresse: .asciiz "à l'adresse: "
RetChar: .asciiz "\n"

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
move $a0 $v0 			# On déplace la valeur que l'utilisateur a entré dans $a0
li $v1, 2 			# On attribue la valeur 2 à $v1
blt $a0, $v1, Affichage 	# On teste si $a0<2 si c'est vrai on recommence à Affichage
mul $a0 $a0 $a0
move $t6 $a0 #On deplace la valeur que l'utilisateur a rentré dans $t6
jal CreerTableau

j Exit 

CreerTableau:
#epilogue
subu $sp $sp 4
sw $ra 0($sp)

# corps de la fonction
move $t0 $a0 #on sauvegarde $a0 dans $t0
li $t5, 15 #valeur pour remplir le tableau
li $t2, 0 #compteur
mul $t3 $t0 4 #$t3: taille en octets
mul $a0 $a0 4 #$a0: taille en octets
li $v0 9 #on lit l'adresse
syscall
move $t1 $v0 #on met l'adresse dans $t1
Boucle:
beq $t2 $t3 TableauCree #si $t2=$t3 ($t2:compteur, $t3: taille en octets) alors c'est qu'on a remplit le tableau
addu $t4 $t1 $t2 #sinon on ajoute la valeur du compteur à l'adresse pour se déplacer dans le tableau et on met ça dans $t4
sw $t5 0($t4) #remplit le tableau avec la valeur 15
addu $t2 $t2 4 #on incremente le compteur de 4
j Boucle #on recommence (:


#epilogue
TableauCree:
move $a0 $t0
move $a1 $t1
jal AfficheTableau
lw $ra 0($sp)
addu $sp $sp 4
jr $ra


#################################Fonction AfficheTableau
###entrées: $a0: taille (en nombre d'entiers) du tableau à afficher
###Pré-conditions: $a0 >=0
###Sorties:
###Post-conditions: les registres temp. $si sont rétablies si utilisées
AfficheTableau:
#prologue:
subu $sp $sp 24
sw $s0 20($sp)
sw $s1 16($sp)
sw $s2 12($sp)
sw $a0 8($sp)
sw $a1 4($sp)
sw $ra 0($sp)

#corps de la fonction:
la $a0 Tableau
li $v0 4
syscall
lw $a0 8($sp)
jal AfficheEntier
la $a0 Aladresse
li $v0 4
syscall
lw $a0 4($sp)
jal AfficheEntier

lw $a0 8($sp)
lw $a1 4($sp)

li $s0 4
mul $s2 $a0 $s0 #$a0: nombre d'octets occupés par le tableau
li $s1 0 #s1: variable incrémentée: offset
LoopAffichage:
bge $s1 $s2 FinLoopAffichage
lw $a1 4($sp)
add $t0 $a1 $s1 #adresse de l'entier: adresse de début du tableau + offset
lw $a0 0($t0)
jal AfficheEntier
addi $s1 $s1 4 #on incrémente la variable
j LoopAffichage

FinLoopAffichage:

beq $s1 $t6 RetourChariot #Si $s1=$t6 ($t6 etant la valeur entrée au départ par l'utilisateur), on fait un retour chariot
RetourChariot:
la $a0 RetChar
li $v0 4
syscall

#épilogue:
lw $s0 20($sp)
lw $s1 16($sp)
lw $s2 12($sp)
lw $a0 8($sp)
lw $a1 4($sp)
lw $ra 0($sp)
addu $sp $sp 24
jr $ra
#########################################################

#################################Fonction AfficheEntier
###entrées: $a0: entier à afficher
###Pré-conditions:
###Sorties:
###Post-conditions:
AfficheEntier:
#prologue:
subu $sp $sp 8
sw $a0 4($sp)
sw $ra 0($sp)

#corps de la fonction:
li $v0 1
syscall

#la $a0 RetChar
#li $v0 4
#syscall

#épilogue:
lw $a0 4($sp)
lw $ra 0($sp)
addu $sp $sp 8
jr $ra
#########################################################

Modulo:
#prologue
subu $sp $sp 8
sw $a0 4($sp)
sw $a1 0($sp)
#corps de la fonction
li $a0 9
li $a1 5
Boucle1:
sub $a0 $a0 $a1
ble $a1 $a0 Boucle1
#epilogue
lw $a0 4($sp)
lw $a1 0($sp)
addi $sp $sp 8

#Résolution d'un labyrinthe
resoudreLabyrinthe:
## à compléter
j Exit

# Fin du programme
Exit:
li $v0 10 
syscall
