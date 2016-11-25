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
	
	jal VideFichier			# On vide d'abord le fichier
	jal MenucaseDetF
	jal AfficheTableau
	
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
	


# Permet de modifier une valeur d'une case du labyrinthe
## $a0 : adresse du 1er élément du tableau
## $a1 : indice du premier élément à modifier
## $a2 : nouvelle valeur
ModifieTableau:
	# prologue 
	subu $sp $sp 20
	sw $a0 16($sp)
	sw $a1 12($sp)
	sw $a2 8($sp)
	sw $s0 4($sp)
	sw $ra 0($sp)

	# corps de la fonction
	mul $s0 $a1 4 		# 4*indice
	add $s0 $s0 $a0 	# là on a désormais la bonne adresse pour la case à modifier
	sw $a2 0($s0) 		# là on met la case désirée à la nouvelle valeur

	#epilogue
	lw $a0 16($sp)
	lw $a1 12($sp)
	lw $a2 8($sp)
	lw $s0 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 20
	
	jr $ra



# Permet d'afficher le contenu d'un tableau carré (N*N)
## Entrée : $a0 = N, le nombre de lignes/colonnes (prec : $a0>=0)
##          $a1 = adresse du premier élément du tableau
AfficheTableau:
	# prologue
	subu $sp $sp 24
	sw $s0 20($sp)
	sw $s1 16($sp)
	sw $a0 12($sp)
	sw $a1 8($sp)
	sw $a2 4($sp)
	sw $ra 0($sp)
	
	
	# corps de la fonction
	move $s0 $a0		# $s0 : nombre de cases par ligne/colonne
	mul $t0 $a0 $a0		# $t0 : nombre total de cases
	mul $t0 $t0 4		# $t0 : taille du tableau en octets
	move $t1 $s0		# $t1 : ième colonne (initialisé à N, dans le but de commencer par un saut de ligne)
	li $t2 0 		# $t2 : offset de la case courante du tableau
	
	jal GetDigits
	li $a0 2 # nombre d'arguments (soit 1, soit 2)
	move $a1 $v0 # premier digit
	move $a2 $v1 # deuxième digit
	jal EcrireDansFichier
	
	BoucleAfficheTableau:
	beq $t2 $t0 FinBoucleAfficheTableau	# Si on a parcouru toutes les cases du tableau, on sort de la boucle
	
	# On traite ici le cas du saut de ligne
	blt $t1 $s0 ApresSautDeLigne		# Si on est pas encore en fin de ligne, on ne saute pas de ligne
	li $t1 0				# On est à nouveau dans la 0ème colonne
	li $a0 1 # nombre d'arguments (soit 1, soit 2)
	li $a1 0x0A # \n en ascii
	jal EcrireDansFichier

	# On traite ici le cas des espaces entre les nombres	
	ApresSautDeLigne:
	beq $t1 0 ApresEspace			# Si on est en début de ligne, pas besoin d'insérer d'espace
	li $a0 1 # nombre d'arguments (soit 1, soit 2)
	li $a1 0x20 # espace en ascii
	jal EcrireDansFichier
	
	ApresEspace:
	lw $a1 8($sp)
	addu $t3 $a1 $t2			# $t3 : adresse de la case courante
	
	# AfficheEntier
	lw $a0 0($t3)				# $a0 contient désormais la valeur de la case courante
	jal GetDigits
	li $a0 2 # nombre d'arguments (soit 1, soit 2)
	move $a1 $v0 # premier digit
	move $a2 $v1 # deuxième digit
	jal EcrireDansFichier
	
	addu $t2 $t2 4				# on incrémente $t2 de 4 (on avance d'une case du tableau, l'offset augmente donc de 4)
	addu $t1 $t1 1				# on incrémente $t1 de 1 (on avance d'une colonne)
	
	j BoucleAfficheTableau
	
	
	# prologue
	FinBoucleAfficheTableau:
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
	li $v0 0 			# par défaut le premier digit vaut 0
	move $v1 $a0 			# on met par défaut v1 à la valeur de a0
	blt $a0 10 FinGetDigits		# Si $a0 <= 10, alors on a fini
	
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


# Modifie le labyrinthe pour ajouter la case de départ et de fin
## Entrées : $a0 : le nombre de lignes/colonnes du labyrinthe entrée par l'utilisateur
##           $a1 : l'adresse de la première case du tableau
## Sortie :  $v0 : l'indice de la case de départ
MenucaseDetF:
	#prologue
	subu $sp $sp 16
	sw $a0 12($sp)
	sw $a1 8($sp)
	sw $a2 4($sp)
	sw $ra 0($sp)
	
	#corps de la fonction
	
	move $t0 $a0 # $t0 vaudra désormais N
	move $t1 $a1 # $t1 vaudra l'adresse de la première case du tableau
	
	
	# on génère les emplacements aléatoires des cases départ et de fin
	## départ d (sera stockée dans $t2)
	li $a0 0
	move $a1 $t0 # borne sup = N
	li $v0 42 # genere un nombre aléatoire dans $a0, 0 <= $a0 < borne sup ($a1)
	syscall
	move $t2 $a0
	
	## arrivée f (sera stockée dans $t3)
	li $a0 0
	move $a1 $t0 # borne sup = N
	li $v0 42 # genere un nombre aléatoire dans $a0, 0 <= $a0 < borne sup ($a1)
	syscall
	move $t3 $a0
	
	
	# on génère maintenant une valeur, qui vaut soit 0, 1, 2, ou 3 pour déterminer la configuration
	li $a0 0
	li $a1 4 # borne sup = N
	li $v0 42 # genere un nombre aléatoire dans $a0, 0 <= $a0 < borne sup ($a1)
	syscall
	move $t4 $a0
	
	# On va donc utiliser la configuration choisie précédemment
	## sera stocké dans $t5 l'indice de la case de départ
	## dans $t6 l'indice de la case de fin
	## $t7 permet juste de réaliser des parties d'opérations
	beq $t4 0 config0
	beq $t4 1 config1
	beq $t4 2 config2
	beq $t4 3 config3
	
	
	# Configuration 0
	## Début D : à gauche	D=d*N
	## Fin F : à droite	F=f*N + N-1
	config0:
	mul $t5 $t2 $s0 #D
	subi $t6 $t0 1
	mul $t7 $t3 $t0
	add $t6 $t6 $t7 #F
	j ConfigOK
	
	# Configuration 1
	## Début D : à droite	D=d*N + N-1
	## Fin F : à gauche	F=f*N
	config1:
	subi $t5 $t0 1
	mul $t7 $t2 $t0
	add $t5 $t5 $t7 #D
	mul $t6 $t3 $t0 #F
	j ConfigOK
	
	# Configuration 2
	## Début D : en haut	D=d
	## Fin F : en bas	F=N*(N-1) + f
	config2:
	move $t5 $t2 #D
	subi $t6 $t0 1
	mul $t6 $t0 $t6
	add $t6 $t6 $t3 #F
	j ConfigOK
	
	# Configuration 3
	## Début D : en bas	D=N*(N-1) + d
	## Fin F : en haut	F=f
	config3:
	subi $t5 $t0 1
	mul $t5 $t0 $t5
	add $t5 $t5 $t2 #D	
	move $t6 $t3 #F
	
	ConfigOK:
	move $a0 $t1 # adresse
	move $a1 $t5 # indice	
	li $a2 31 # nouvelle valeur (15 (tous les murs) + 16 (casé départ))
	jal ModifieTableau
	
	move $a0 $t1 # adresse
	move $a1 $t6 # indice	
	li $a2 47 # nouvelle valeur (15 (tous les murs) + 32 (casé fin))
	jal ModifieTableau
		
	#epilogue
	move $v0 $t5
	
	lw $a0 12($sp)
	lw $a1 8($sp)
	lw $a2 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 16
	
	jr $ra
	
# Fonction qui test si une case a été visitée
## Entrée : $a0 : adresse du premier élément du tableau
## 	    $a1 : indice de la case
## Sortie : $v0 : 0 si la case n'a pas été visitée et 1 sinon
TestVisite:
	#prologue 
	subu $sp $sp 8
	sw $a0 4($sp)
	sw $ra 0($sp)
	#corps de la fonction
	mul $a1 $a1 4 # 4*indice
	add $a1 $a1 $a0 # $a1 contient l'adresse de la case
	sw $s1 0($a1) # on met la valeur de la case dans $s1
	li $t1 0 #on initialise la valeur test $t1 à 0
	ble $s1 128 Fin # on test si la valeur de la case est <128
	li $t1 1 #si c'est vrai on change la valeur de $t1 en 1
	Fin: #sinon on jump à fin
	move $v0 $t1 #on met la valeur de $t1 dans $v0

	#epilogue
	lw $a0 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 8
	
	jr $ra

# Retourne les indices des différents voisins d'une case
## Entrée : $a0 : indice X de la case courante
##          $a1 : valeur de N entrée au début par l'utilisateur
##          $a3 : adresse du premier élément du tableau contenant le labyrinthe
## Sortie : $v0 : l'indice d'un des voisins choisis aléatoirement (vaut -1 si aucun voisin)
##          $v1 : valeur pour identifier la direction (0 : haut, 1 : droite, 2 : bas, 3 : gauche)
Voisin:
	#prologue
	subu $sp $sp 20
	sw $a0 16($sp)
	sw $a1 12($sp)
	sw $a2 8($sp)
	sw $a3 4($sp)
	sw $ra 0($sp) 
	
	
	#corps de la fonction
	li $s0 0		# compteur du nombre de voisins qu'on initialise à 0
	move $t0 $a0		# On sauvegarde la valeur de $a0 dans $t0 : X
	move $t1 $a1		# On sauvegarde la valeur de $a1 dans $t1 : N
	move $t6 $a3 		# On sauvegarde la valeur de $a3 dans $t6 : adresse du premier élément du tableau
	div $t2 $t0 $t1
	mfhi $t2 		# X%N
	
	# valeurs pour les tests
	subi $t3 $t1 1 # $t3=N-1
	mul $t4 $t1 $t3 # $t4=N*(N-1)
	
	# Traitement des differents cas
	beq $t2 0 FinVoisinGauche # Si X%N = 0 alors pas de voisin à gauche
	move $a2 $t3 # sinon l'indice vaut N-1 
	move $a0 $t6 #On met l'adresse du premier élément du tableau dans $a0
	move $a1 $t3 #On met l'indice de la case voisine dans $a1
	jal TestVisite
	move $a0 $t0 #On remet la bonne valeur dans $a0
	move $a1 $t1 #On remet la bonne valeur dans $a1
	beq $v0 1 FinVoisinGauche #Si le voisin a été visité on incremente pas
	addi $s0 $s0 8 # on incremente le compteur de 8
	subu $sp $sp 8 # on fait de la place sur la pile pour stocker l'indice de ce voisin
	li $t5 3 # direction : gauche
	sw $t5 4($sp)
	sw $a0 0($sp) # on sauvegarde l'indice du voisin trouvé sur la pile
	
	FinVoisinGauche:
	beq $t3 $t2 FinVoisinDroite # Si X%N = N-1 alors pas de voisin à droite
	addi $a0 $t0 1 # sinon l'indice vaut N+1
	move $a0 $t6 #On met l'adresse du premier élément du tableau dans $a0
	move $a1 $t3 #On met l'indice de la case voisine dans $a1
	jal TestVisite
	move $a0 $t0 #On remet la bonne valeur dans $a0
	move $a1 $t1 #On remet la bonne valeur dans $a1
	beq $v0 1 FinVoisinGauche #Si le voisin a été visité on incremente pas
	addi $s0 $s0 8 # on incremente le compteur de 8
	subu $sp $sp 8 # on fait de la place sur la pile pour stocker l'indice de ce voisin
	li $t5 1 # direction : droite
	sw $t5 4($sp)
	sw $a0 0($sp) # on sauvegarde l'indice du voisin trouvé sur la pile
		
	FinVoisinDroite:
	blt $t0 $t1 FinVoisinHaut #Si X<N alors il n'y a pas de voisin en haut
	sub $a0 $t0 $t1 # sinon l'indice vaut X-N
	move $a0 $t6 #On met l'adresse du premier élément du tableau dans $a0
	move $a1 $t3 #On met l'indice de la case voisine dans $a1
	jal TestVisite
	move $a0 $t0 #On remet la bonne valeur dans $a0
	move $a1 $t1 #On remet la bonne valeur dans $a1
	beq $v0 1 FinVoisinGauche #Si le voisin a été visité on incremente pas
	addi $s0 $s0 8 # on incremente le compteur de 8
	subu $sp $sp 8 # on fait de la place sur la pile pour stocker l'indice de ce voisin
	li $t5 0 # direction : haut
	sw $t5 4($sp)
	sw $a0 0($sp) # on sauvegarde l'indice du voisin trouvé sur la pile
	
	FinVoisinHaut:
	bge $t0 $t4 FinVoisinBas # Si X >= N*(N-1) alors il n'y a pas de voisin en bas
	add $a0 $t0 $t1 # Sinon l'infice vaut X+N
	move $a0 $t6 #On met l'adresse du premier élément du tableau dans $a0
	move $a1 $t3 #On met l'indice de la case voisine dans $a1
	jal TestVisite
	move $a0 $t0 #On remet la bonne valeur dans $a0
	move $a1 $t1 #On remet la bonne valeur dans $a1
	beq $v0 1 FinVoisinGauche #Si le voisin a été visité on incremente pas
	addi $s0 $s0 8 # on incremente le compteur de 8
	subu $sp $sp 8 # on fait de la place sur la pile pour stocker l'indice de ce voisin
	li $t5 2 # direction : bas
	sw $t5 4($sp)
	sw $a0 0($sp) # on sauvegarde l'indice du voisin trouvé sur la pile
	
	FinVoisinBas:
	li $v0 -1 # valeur de retour par défaut
	li $v1 -1 # valeur de retour par défaut
	
	div $s1 $s0 8 # on récupère le nombre de voisins ajoutés sur la pile
	beq $s1 $0 FinVoisin # si aucun voisin n'a été trouvé, on a pas besoin de faire ce qui suit
	
	li $a0 0
	move $a1 $s1 # borne sup = $s1
	li $v0 42 # genere un nombre aléatoire dans $a0, 0 <= $a0 < borne sup ($a1)
	syscall
	move $s2 $a0
	mul $s2 $s2 8 # on calcul l'offset poure récupérer le bon voisin
	addu $s2 $sp $s2 # on récupère la bonne adresse sur la pile
	lw $v0 0($s2) # $v0 contient désormais l'indice d'un voisin choisi aléatoirement
	lw $v1 4($s2) # $v1 contient désormais la direction (0 : haut, 1 : droite, 2 : bas, 3 : gauche)
		
	addu $sp $sp $s0 # on libère la place sur la pile
	
	# epilogue
	FinVoisin:
	lw $a0 16($sp)
	lw $a1 12($sp)
	lw $a2 8($sp)
	lw $a3 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 20
	
	jr $ra

## Fonction qui sert à détruire les murs
# $a1 : Indice de la case courante actuelle
# $a2 : Indice de la prochaine case courante
# $a3 : Valeur de la direction dans laquelle on va

#prologue
	subu $sp $sp 16
	sw $a1 12($sp)
	sw $a2 8($sp)
	sw $a3 4($sp)
	sw $ra 0($sp)

#corps de la fonction
	mul $t0 $a1 4 # offset1
	mul $t1 $a2 4 # offset2
	add $t0 $a0 $t0 #dans $t0 on a l'adresse de la case courante actuelle
	add $t1 $a0 $t1 #dans $t1 on a l'adresse de la prochaine case courante
	lw $s1 0($t0) #on stocke la valeur de la case courante actuelle du tableau dans $s1 
	lw $s2 0($t1) #on stocke la valeur de la prochaine case courante dans $s2
	move $a1 $t0 #On deplace l'adresse de la case courante actuelle dans $a1
	move $a1 $t1 #On deplace l'adresse de la prochaine case courante dans $a1
	beq $a3 0 AllerHaut #Si $a0  vaut 0 cela veut dire qu'on doit déplacer la case courante en haut
	beq $a3 1 AllerDroite #Si $a0  vaut 1 cela veut dire qu'on doit déplacer la case courante à droite
	beq $a3 2 AllerBas #Si $a0  vaut 2 cela veut dire qu'on doit déplacer la case courante en bas
	beq $a3 3 AllerGauche #Si $a0  vaut 3 cela veut dire qu'on doit déplacer la case courante à gauche
	AllerHaut:
		subi $a2 $s1 1 #On soustrait 1 à la valeur de la case courante 
		jal ModifieTableau #On detruit le mur du haut de la case courante
		subi $a2 $s2 4 #On soustrait 4 (100 en binaire) à la valeur de la nouvelle case courante
		jal ModifieTableau #On detruit le mur du bas de la nouvelle case courante
	AllerDroite:
		subi $a2 $s1 2 #On soustrait 2 (10 en binaire) à la valeur de la case courante 
		jal ModifieTableau #On detruit le mur à droite de la case courante
		subi $a2 $s2 8 #On soustrait 8 (1000 en binaire) à la valeur de la nouvelle case courante
		jal ModifieTableau #On detruit le mur de gauche de la nouvelle case courante
	AllerGauche:
		subi $a2 $s1 8 #On soustrait 8 (1000 en binaire) à la valeur de la case courante 
		jal ModifieTableau #On detruit le mur à gauche de la case courante
		subi $a2 $s2 2 #On soustrait 2 (10 en binaire) à la valeur de la nouvelle case courante
		jal ModifieTableau #On detruit le mur de droite de la nouvelle case courante
	AllerBas:
		subi $a2 $s1 4  #On soustrait 4 (100 en binaire) à la valeur de la case courante 
		jal ModifieTableau #On detruit le mur du bas de la case courante
		subi $a2 $s2 1 #On soustrait 1 à la valeur de la nouvelle case courante
		jal ModifieTableau #On detruit le mur du haut de la nouvelle case courante
	
	#epilogue
	lw $a1 12($sp)
	lw $a2 8($sp)
	lw $a3 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 16
	
	jr $ra

# Permet de marquer une case comme visitée
## $a0 : adresse du premier élément du tableau
## $a1 : indice de la case à marquer comme visitée
MarqueVisite:
	subu $sp $sp 12
	sw $a0 8($sp)
	sw $a1 4($sp)
	sw $ra 0($sp)
	
	#corps de la fonction
	mul $t0 $a1 4 # offset
	add $t0 $a0 $t0 #dans $t0 on a l'adresse de la case à modifier
	lw $t1 0($t0) #on stocke la valeur de la case du tableau dans $t0 
	addi $a2 $t1 128 #on ajoute 128 à cette valeur
	jal ModifieTableau #on modifie le tableau
	
	#epilogue
	lw $a2 4($sp)
	lw $ra 0($sp)
	addu $sp $sp 8
	
	jr $ra
	
#Résolution d'un labyrinthe
resoudreLabyrinthe:
## à compléter
j Exit

# Fin du programme
Exit:
li $v0 10 
syscall
