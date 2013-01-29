;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	Exemple d'affichage de background
;	Affiche un background composé de 3 tiles différentes
;	Création: Louis Marchand, 27 mars 2010
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;; Entète de la rom ;;;;;;;;;;;
	.inesprg 1 ; 1 banque de 16KB (2 banque de 8KB) pour le programme
	.ineschr 1 ; 1 banque de 8KB pour les image (2 tables de motifs)
	.inesmap 0 ; mapper 0 = NROM, Banque par défaut
	.inesmir 1 ; Mirroir vertical de l'image de fond

;;;;;;; Le code commence ici ;;;;;;;;
	.code

	.bank 0   ; Banque 0 (8KB de $0000 à $DFFF
	.org $8000  ; goto location $8000.


Start:
	SEI         ; Arreter les interruption, Met le bit I du registre P (etat du processeur) a 1
	CLD         ; Arrete le mode decimal. Met le bit D du registre P à 0
	LDX #$40
	STX $4017  ;  Met $40 dans le registre de controle de l'APU pour arreter les interruptions de l'APU
	LDX #$FF
	TXS         ; Initialise la pile. Place X ($FF$ comme octet moins significatif de l'adresse de la pile). La pile est toujours entre $0100 et $01FF.
	INX         ; Lorsqu'on incremente X qui contient $FF, C tombe à 0
	STX $2000  ;  Arrete les interruption NMI (Bit 7 du registre Contrôle PPU)
	STX $2001  ;  N'affiche rien (Voir bits 3 à 7 du registre Masque PPU)
	STX $4010  ;  Arrete les interruption logiciel

vblankwait1:
	BIT $2002		; Bit place les Code de condition N, V, Z.
	BPL vblankwait1	; Si le bit 7 est allumé, on a un vblank (BPL = N flag clear, le bit de negatif = bit 7)

clrmem:
	LDA #$00
	;STA $0000,  x		; Place tous les octets à 0 (", x" correspond a l'adressage indexe avec le registre x)
	STA $0100,  x
	STA $0300,  x
	STA $0400,  x
	STA $0500,  x
	STA $0600,  x
	STA $0700, x
	LDA #$FE
	STA $0200, x		; Placer tous les sprite en dehors de l'écran
	INX
	BNE clrmem		; Branche si non zero (lorsque x a fait le tour des valeurs de 0 à FF)

vblankwait2:			; Attent le prochain vblank (voir vblankwait1)
	BIT $2002
	BPL vblankwait2


;;;;  Initialise le PPU  ;;;;

LoadPalettes:
 	LDA $2002    		; Lire le registre d'etat du PPU ou annuler le latch de $2006 (s'il y a lieu)
	LDA #$3F	
	STA $2006    		; Place les 8 bits les plus significatifs de l'adresse $3F00 dans $2006
	LDA #$00
	STA $2006    		; Place les 8 bits les moins significatifs de l'adresse $3F00 dans $2006
	LDX #$00
LoadPalettesLoop:
	LDA Palette, x		; Charge les donnees de la palette (", x" correspond a l'adressage indexe avec le registre x)
	STA $2007		; Place les informations du PPU (l'adresse d'écriture de $2007 incrémente automatiquement de 1 octet après chaque ecriture)
	INX			; Prochain index a aller chercher dans la palette en memoire rom (etiquette palette+x)
	CPX #$20            
	BNE LoadPalettesLoop 	; La palette est completement copiees si x est à $20=32=16x2

LoadName:
	LDA #$20	; Nous utiliserons la table de nom 0 (Adr $2000)
	STA $2006
	LDA #$00
	STA $2006
	LDX #$00	; x sera notre index de largeur
	LDY #$00	; y sera notre index de hauteur
LoadNameLoop:
	STA $2007	; Mettre la tuille no 0 dans la table
	INX
	CPX #32
	BNE LoadNameLoop	; Lorsque x=32, on a une ligne pleine
	LDX #$00
	INY
	CPY #30
	BNE LoadNameLoop	; lorsque y=30, on a terminer (32x30 tuiles)

	LDX #$00
LoadAttribute:
	LDA #%00011011	; Changer cette valeur pour changer la sous-palette de couleur à utiliser (2 bits par 2x2 tuiles)
	STA $2007
	INX
	CPX #64
	BNE LoadAttribute ; Il y a 64 attribut

;;;;  Fin de l'initialisation du PPU  ;;;;

;;;;  Commencer l'affichage du PPU  ;;;;

	LDX #$20		; Initialisation des données pour l'interruption NMI
	LDY #$20		; Initialisation des données pour l'interruption NMI
	LDA #1
	STA var1


vblankwait3:		; Attent le prochain vblank
	BIT $2002
	BPL vblankwait3

activePPU:
	LDA #%10010100		; Active les interruption NMI, table de motif: sprite = 0 et image de fond = 1
	STA $2000
	LDA #%11101110		; Active l'image de fond, mais pas les sprites
	STA $2001
	LDA #$00		;Ne pas faire de defilement d'image
	STA $2005
	STA $2005


Forever:
  JMP Forever     ;Boucle sans fin, le processus se fera lors d'interruption


NMI:	; A chaque vblank, on ajoute une tuile
	LDA $2002		; On s'assure qu'il n'y a pas de latch dans $2006
	STY $2006		; y contient l'octet le plus significatif de l'adresse de tuile a afficher
	STX $2006		; x contient l'octet le moins significatif de l'adresse de tuile a afficher
	LDA var1		; Si var1 = 1 (resp. 2), on affiche le motif de background 1 (resp. 2) 
 	STA $2007

	LDA #%10010100   	; On s'assure que le PPU fait ce que l'on veut. Voir activePPU
	STA $2000
	LDA #%11101110   
	STA $2001
	LDA #$00        
	STA $2005
	STA $2005

	INX			; On prepare les information pour la prochaine iteration
	CPY #$23		; A noter que meme si le vblank se termine, nous n'utilisons plus le PPU
	BEQ NMI10
	CPX #$00
	BNE NMI20
	INY
	JMP NMI20
NMI10:
	CPX #$C0
	BNE NMI20
	LDX #$20		; On a terminer d'afficher les tuiles, on passe aux prochaines tuiles
	LDY #$20		; Les tuiles de la premiere ligne ($00 à $20) sont a l'exterieur de l'ecran
	LDA var1
	CMP #1
	BNE NMI15		
	LDA #2			; Si var1 = 1, on met 2 dans var1
	STA var1
	JMP NMI20
NMI15:
	LDA #1			; Si var1 = 2, on met 1 dans var1
	STA var1

NMI20:
	RTI             ; retourne de l'interruption


;;;;; La prochaine section est une partie du ROM de la cartouche il est possible de mettre du code ici. Nous allons l'utiliser pour mettre des constantes ;;;;;;

	.bank 1		; Banque 1 (8KB de $E000 à $FFFF)
	.org $E000	; Donnees en lecture seulement (similaire au rodata)

Palette:
	.db $30, $20, $10, $00, $3A, $2A, $1A, $0A, $37, $27, $17, $07, $32, $22, $12, $02	; Palette de l'image de fond
	.db $30, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00	; Palette des sprites




	.org $FFFA	; vecteur d'interruption commence à $FFFA

	.dw NMI		; Interruption NMI (vblank). Adresse $FFFA
	.dw Start	; Interruption Reset (demarrage). Adresse $FFFC
	.dw 0		; Interruption logiciel (instruction BRK). Adresse $FFFE




;;;;; La prochaine section est une partie du ROM qui correspond aux adresse $0000 à $1FFF de la vram du PPU ;;;;;;

	.bank 2        ; change to bank 2
	.org $0000

	; Ini, on place les tuile pour le sprite

	.org $1000	; Motif de background
Background:	; Tuile 0
	.db %00000000, %00000000
	.db %00000000, %00000000
	.db %00000000, %00000000
	.db %00000000, %00000000
	.db %00000000, %00000000
	.db %00000000, %00000000
	.db %00000000, %00000000
	.db %00000000, %00000000

BackgroundMotif1:	; Tuile 1
	.db %10100010		; Bit le moins significatif de la premiere ligne de la tile
	.db %01010001		; Bit le moins significatif de la deuxieme ligne de la tile
	.db %10101000		; Bit le moins significatif de la troisieme ligne de la tile
	.db %01010100		; Bit le moins significatif de la quatrieme ligne de la tile
	.db %00101010		; Bit le moins significatif de la cinquieme ligne de la tile
	.db %00010101		; Bit le moins significatif de la cixieme ligne de la tile
	.db %10001010		; Bit le moins significatif de la septieme ligne de la tile
	.db %01000101		; Bit le moins significatif de la huitieme ligne de la tile

	.db %11000001		; 2e Bit le moins significatif de la premiere ligne de la tile
	.db %11100000		; 2e Bit le moins significatif de la deuxieme ligne de la tile
	.db %01110000		; 2e Bit le moins significatif de la troisieme ligne de la tile
	.db %00111000		; 2e Bit le moins significatif de la quatrieme ligne de la tile
	.db %00011100		; 2e Bit le moins significatif de la cinquieme ligne de la tile
	.db %00001110		; 2e Bit le moins significatif de la cixieme ligne de la tile
	.db %00000111		; 2e Bit le moins significatif de la septieme ligne de la tile
	.db %10000011		; 2e Bit le moins significatif de la huitieme ligne de la tile

BackgroundMotif2:	; Tuile 2
	.db %01000101		; Bit le moins significatif de la premiere ligne de la tile
	.db %10001010		; Bit le moins significatif de la deuxieme ligne de la tile
	.db %00010101		; Bit le moins significatif de la troisieme ligne de la tile
	.db %00101010		; Bit le moins significatif de la quatrieme ligne de la tile
	.db %01010100		; Bit le moins significatif de la cinquieme ligne de la tile
	.db %10101000		; Bit le moins significatif de la cixieme ligne de la tile
	.db %01010001		; Bit le moins significatif de la septieme ligne de la tile
	.db %10100010		; Bit le moins significatif de la huitieme ligne de la tile

	.db %10000011		; 2e Bit le moins significatif de la premiere ligne de la tile
	.db %00000111		; 2e Bit le moins significatif de la deuxieme ligne de la tile
	.db %00001110		; 2e Bit le moins significatif de la troisieme ligne de la tile
	.db %00011100		; 2e Bit le moins significatif de la quatrieme ligne de la tile
	.db %00111000		; 2e Bit le moins significatif de la cinquieme ligne de la tile
	.db %01110000		; 2e Bit le moins significatif de la cixieme ligne de la tile
	.db %11100000		; 2e Bit le moins significatif de la septieme ligne de la tile
	.db %11000001		; 2e Bit le moins significatif de la huitieme ligne de la tile





;;;;; La prochaine section n'est pas dans la cartouche, elle est en RAM du NES ;;;;;;

	.zp	; Zero page bank (memoire rapide $0000 à $00FF).
	.org $0000  
		; Définir les variables ici
var1:	.ds 1	; Puisque la RAM du nes n'est pas dans la cartouche, l'initialisation n'est pas prise en compte (ne vous attendez pas à avoir 0 dans cette mémoire par défaut).


	.bss 	; RAM (memoire de $0200 à $07FF). Ne pas utiliser la mémoire $0100 à $01FF car c'est la stack. Nous utiliserons $0200 à $02FF pour les spritesNe
	.org $0300
var2:	.ds 3	; Variable innutiliser, ce n'est qu'un exemple

