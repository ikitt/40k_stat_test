=begin ###################################
                 #TERMINOLOGIE#
       ###################################

* Figurine
  * Cible
* Arme
  * ArmeCaC
  * ArmeTir
* Unite
* Datasheet
* Faction
* Situation
* CapaciteSpeciale

       ###################################
=end   ###################################

=begin ###################################
                  #TODO LIST#
       ###################################

* Créer une structure Resultat (:valeur, :probabilite)
* Créer une class Jet avec une liste de Resultat, des method de relance
* Voir pour repenser les relances comme une profondeur d'arbre (sur D3, relance des 1 [1,2,3] => [[1,2,3],[2,2,2],[3,3,3]]
* Créer la classe Unite qui regroupe plusieurs Figurines
* Etoffer la class ValeurAleatoire

       ###################################
=end   ###################################

# Prend un nombre en entrée et sort un string avec le bon nbr_de_carac en sorti.
# Un caractere pour le signe est compter. '-' pour un nombre négatif et ' ' pour un positif.
def string_avec_caractere nombre, nbr_de_carac_avant = 5, nbr_de_carac_apres = 3
  sortie = (nombre < 0) ? '' : ' '
  nbr_espace_avant = nbr_de_carac_avant - (nombre.round 0).to_s.size - sortie.size
  espace_avant = ''
  nbr_espace_avant.times {espace_avant << ' '} if nbr_espace_avant > 0
  sortie = espace_avant + sortie

  if nombre.ceil == nombre #pas de virgule
    sortie << nombre.ceil.to_s
    (nbr_de_carc_apres + 1).times {sortie << ' '} #+1 pour la virgule
  else
    nrb_chiffre_arpes_virgule = (nombre.to_s.split '.')[1].size
    if nrb_chiffre_arpes_virgule < nbr_de_carac_apres
      sortie << nombre.to_s
      (nbr_de_carac_apres - nrb_chiffre_arpes_virgule).times { sortie << ' '}
    else
      arrondi = nombre.round(nbr_de_carac_apres).to_s
      arrondi << '0' while ((arrondi.split '.')[1].size < nbr_de_carac_apres) #Ajout des 0 à la fin de nombre qui sont retirer automatiquement
      sortie << arrondi.to_s
    end
  end
  sortie
end

class Array
  def copie
    self.map{|item| item.copie}
  end
end

module JetDes

  class ValeurIncorrect < StandardError
  end

  class ValeurAleatoire
    def initialize value
      @azer = value[1..-1].to_f
    end

    def method_missing(m, *args)
      @azer.send(m,*args)
    end

    def coerce arg
      @azer.coerce arg
    end
  end

  def self.max_size vecteur
    vecteur.map{|val| val.nom.size}.max
  end


  def self.getCarac(proprio, carac, valeurs_admise)
    p "#{proprio} : #{carac} ? #{valeurs_admise}"
    valeur = gets.chomp.to_i
    return valeur if  valeurs_admise.include? valeur
    #else
    p "La valeur #{valeur} est incorrect"
    raise ValeurIncorrect.new
  rescue ValeurIncorrect => e
    retry
  end

  def self.score_bless force, endu
    #   p "    (#{force}.to_f / #{endu}.to_f) = #{(force.to_f / endu.to_f)}"
    return 6 if (force.to_f / endu.to_f) <= 0.5
    return 5 if (force.to_f / endu.to_f) < 1
    return 4 if (force.to_f / endu.to_f) == 1
    return 3 if (force.to_f / endu.to_f) < 2
    return 2
  end

  def self.force_cac(combattant, arme_de_cac)
    return arme_de_cac.force if arme_de_cac.force.is_a? Numeric
    return combattant.force + arme_de_cac.force[1..-1].to_i if arme_de_cac.force[0] == '+'
    return combattant.force * arme_de_cac.force[1..-1].to_i if arme_de_cac.force.start_with?('*' , 'x')
    return combattant.force if arme_de_cac.force == 'utilisateur'
  end

  def self.chance_succes_des(difficulte, nombre_faces = 6)
    return 0 if difficulte > nombre_faces
    return 1 if difficulte <= 1
    (nombre_faces + 1 - difficulte)/nombre_faces.to_f
  end

  def self.chance_succes_des_avec_relance(difficulte, nombre_faces = 6, relance_faces = [1])
    reussite_premier_jet = chance_succes_des(difficulte, nombre_faces)
    reussite_sur_relance = (relance_faces.map{chance_succes_des(difficulte, nombre_faces)}.inject(:+))/nombre_faces.to_f
    reussite_premier_jet + reussite_sur_relance
  end


  def self.chance_echec_des(difficulte, nombre_faces = 6)
    return 1 if difficulte > nombre_faces
    return 0 if difficulte <= 1
    (difficulte - 1)/nombre_faces.to_f
  end

  def self.valeur_moyenne_des nombre_de_face
    somme_face = (1..nombre_de_face).inject { |sum, n| sum + n }
    moyenne = somme_face.to_f / nombre_de_face.to_f
  end

  def self.proba_meilleur_jet nombre_de_des, nombre_de_face
    JetDes::remplissage_resultat(nombre_de_des, nombre_de_face).map{|groupe| groupe.max}.inject{|idx,somme| idx + somme}/(nombre_de_face**nombre_de_des).to_f
  end

  def self.remplissage_resultat(nombre_de_des, nombre_de_face, des_courant = 1, vecteur_des_possibles=[])
    maj_vecteur_des_possibles = []
    if vecteur_des_possibles.empty?
      nombre_de_face.times { |idx| maj_vecteur_des_possibles << [idx+1] }
    else
      vecteur_des_possibles.each do |groupe_lances|
        nombre_de_face.times { |idx| maj_vecteur_des_possibles << (Array.new(groupe_lances) << (idx+1)) }
      end
    end

    des_courant == nombre_de_des ? maj_vecteur_des_possibles : remplissage_resultat(nombre_de_des, nombre_de_face, des_courant+1, maj_vecteur_des_possibles)
  end


  def self.capa_fusil_disrupteur situation
    proba_D3_BM = JetDes::chance_succes_des(6)
    proba_1_BM = JetDes::chance_succes_des(4) - proba_D3_BM
    nbr_BM = (proba_1_BM*1 +  proba_D3_BM*JetDes::valeur_moyenne_des(3))
    situation.blessures_mortelles_par_salve += nbr_BM * situation.arme.attaque * situation.touche_par_tir
  end

  def self.addition_caracteristique situation, cible, caracteristique, modificateur
    carac_de_base = situation.instance_variable_get(cible).instance_variable_get(caracteristique)
    situation.instance_variable_get(cible).instance_variable_set(caracteristique, carac_de_base + modificateur)
  end

  def self.multiplication_caracteristique situation, cible, caracteristique, modificateur
    carac_de_base = situation.instance_variable_get(cible).instance_variable_get(caracteristique)
    p "passe la carac #{caracteristique} du #{cible} de #{carac_de_base} à #{carac_de_base.to_f * modificateur.to_f}"
    situation.instance_variable_get(cible).instance_variable_set(caracteristique, carac_de_base.to_f * modificateur.to_f)
  end

  #Ne prend pas en compte le fait que si il y a modification des chances de succes (genre -1 à la CT), la relance se fait avant l'application du modificateur
  #Ne prend pas en compte le fait qu'on ne peut relancer qu'un seul dé.
  def self.relance_des_1 situation, jet
    proba_de_base = situation.instance_variable_get(jet)
    situation.instance_variable_set(jet, proba_de_base*7/6.0)
  end

  def self.relance_complete situation, jet
    proba_de_base = situation.instance_variable_get(jet)
    p "proba_de_base #{proba_de_base}, proba_de_base + ((1-proba_de_base)*proba_de_base) #{proba_de_base + ((1-proba_de_base)*proba_de_base)}"
    situation.instance_variable_set(jet, proba_de_base + ((1-proba_de_base)*proba_de_base))
  end

  def self.arme_empoisonnee situation, score
    score = situation.cible.mots_cles.include?('vehicule') ? 6 : score #Les arme empoisonnée blessent les véhicule sur 6+
    p "C'est un véhicule ? #{situation.cible.mots_cles.include?('vehicule')}, : #{situation.cible.inspect}" #TRVD
    situation.instance_variable_set('@bless_par_touche', JetDes::chance_succes_des(score))
  end

  def self.insensible_a_la_douleur situation, score
    degat_finaux = situation.instance_variable_get('@degat_par_salve') * ((score-1).to_f / 6.0)
    situation.instance_variable_set('@degat_par_salve', degat_finaux)
  end

  class Arme
    def to_s
      @nom
    end
  end

  #ajouter gestion des 'D6 + 2'
  class ArmeTir < Arme
    extend JetDes
    attr_accessor :nom, :type, :attaque, :porte, :force, :pa, :degat_moyen, :capacites_speciales
    def initialize(nom, type, attaque, porte, force, pa, degat, capacites_speciales = [])
      @nom = nom
      @type = type
      @attaque = attaque
      @porte = porte
      @force = force.to_f
      @pa = pa
      @degat = degat
      @capacites_speciales = capacites_speciales
      if degat.is_a? String
        nombre_faces_degat = @degat[1..-1].to_i
        @degat_moyen = JetDes::valeur_moyenne_des nombre_faces_degat
        p "degat_moyen de #{@nom} = #{@degat_moyen}"
      else
        @degat_moyen = @degat
      end
    end

    def copie
      ArmeTir.new(@nom, @type, @attaque, @porte, @force, @pa, @degat, @capacites_speciales)
    end

    def degat
      return @degat if @degat.is_a? Numeric
      nombre_faces = @degat[1..-1].to_i
      return rand(1..nombre_faces)
    end

  end

  class ArmeCaC < Arme
    attr_accessor :nom, :force, :pa, :degat_moyen, :capacites_speciales
    def initialize(nom, force, pa, degat, capacites_speciales = [])
      @nom = nom
      @force = force
      @pa = pa
      @degat = degat
      @capacites_speciales = capacites_speciales
      if degat.is_a? String
        nombre_faces_degat = @degat[1..-1].to_i
        somme_face = (1..nombre_faces_degat).inject { |sum, n| sum + n }
        @degat_moyen = somme_face.to_f / nombre_faces_degat.to_f
        p "degat_moyen de #{@nom} = #{@degat_moyen}"
      else
        @degat_moyen = @degat
      end
    end

    def copie
      ArmeCaC.new(@nom, @force, @pa, @degat, @capacites_speciales)
    end

    def degat
      return @degat if @degat.is_a? Numeric
      nombre_faces = @degat[1..-1].to_i
      return rand(1..nombre_faces)
    end

  end

  class Figurine
    attr_accessor :nom, :mouvement, :cc, :ct, :force, :endu, :pv, :attaque, :commandement, :svg_armure, :svg_invu, :distance, :mots_cles, :capacites_speciales, :armes

    def initialize(nom, mouvement, cc, ct, force, endu, pv, attaque, commandement, svg_armure, svg_invu = nil, distance = 2, mots_cles = [], capacites_speciales = [], armes = [])
      @nom = nom
      @mouvement = mouvement
      @pv = pv
      @cc = cc
      @ct = ct
      @force = force
      @endu = endu
      @pv = pv
      @attaque = attaque
      @commandement = commandement
      @svg_armure = svg_armure
      @svg_invu = svg_invu
      @distance = distance
      @mots_cles = mots_cles
      @capacites_speciales = capacites_speciales
      @armes = armes
    end

    def to_s
      @nom
    end

    def copie
      capacites = @capacites_speciales.map{|capa| capa.respond_to?(:copie) ? capa.copie : capa}
      Figurine.new(@nom, @mouvement, @cc, @ct, @force, @endu, @pv, @attaque, @commandement, @svg_armure, @svg_invu, @distance, @mots_cles, @capacites_speciales, @armes.copie)
    end

    def meilleur_save(pa)
      return [@svg_armure - pa, 0].max if @svg_invu.nil?
      [@svg_armure - pa, @svg_invu, 7].min
    end
  end

  class Tireur < Figurine
    attr_accessor :nom, :ct, :capacites_speciales
    def initialize(nom, ct, capacites_speciales = [])
      @nom = nom
      ct = JetDes::getCarac('Tireur', 'CT', [2, 3, 4, 5, 6]) if ct.nil?
      @ct = ct
      @capacites_speciales = capacites_speciales
    end

    def copie
      Tireur.new(@nom, @ct, @capacites_speciales)
    end
  end

  class Combattant < Figurine
    attr_accessor :nom, :cc, :force, :attaque, :capacites_speciales
    def initialize(nom, cc, force, attaque, capacites_speciales = [])
      @nom = nom
      @cc = cc
      @force = force
      @attaque = attaque
      @capacites_speciales = capacites_speciales
    end

    def copie
      Combattant.new(@nom, @cc, @force, @attaque, @capacites_speciales)
    end
  end

  class Cible < Figurine
    attr_accessor :nom, :endu, :svg_armure, :svg_invu, :pv, :distance, :capacites_speciales
    def initialize(nom, endu, svg_armure, svg_invu, pv, distance, capacites_speciales = [])
      @nom = nom
      @endu = endu
      @svg_armure = svg_armure
      @svg_invu = svg_invu
      @pv = pv
      @distance = distance
      @capacites_speciales = capacites_speciales
    end

    def copie
      Cible.new(@nom, @endu, @svg_armure, @svg_invu, @pv, @distance, @capacites_speciales)
    end

    def meilleur_save(pa)
      #     p "    meilleur_save du #{@nom} avec pa #{pa} = #{@svg_invu.nil? ? [@svg_armure - pa, 0].max :  [@svg_armure - pa, @svg_invu, 0].max}"
      return [@svg_armure - pa, 0].max if @svg_invu.nil?
      [@svg_armure - pa, @svg_invu, 7].min
    end
  end

  class Unite
    attr_accessor :figurines

    def initialize fig = []
      @figurines = fig
    end

    def copie
      Unite.new @figurines.map {|fig| fig.copie}
    end

    def << fig
      case fig
      when Array
        fig.each{|item| self << item.copie}
      when Figurine
        @figurines << fig
      else
        raise "Unite::<< autorisé pour des Figurines ou des Array de Figurine, pas pour des #{fig.class}"
      end
    end

    def to_s
      hash_unite = {}
      @figurines.each do |fig|
        hash_unite[fig.nom].nil? ? hash_unite[fig.nom] = 1 : hash_unite[fig.nom] += 1
      end
      retour = ""
      hash_unite.each_with_index do |(nom, nbr), idx|
        retour << ', ' if idx > 0
        retour << "#{nbr} #{nom}"
      end
      retour
    end

  end

  class Faction
    attr_accessor :nom, :unites, :arsenal

    class << self
      attr_accessor :liste_des_factions
    end
    @liste_des_factions = []

    def initialize nom, unites = [], arsenal = []
      @nom = nom
      @unites = unites
      @arsenal = arsenal
      self.class.liste_des_factions << self
    end

    def << *args
      args.each do |arg|
        p "Ajoute  #{arg.nom} (#{arg.class}) à la faction #{self.nom}." + ((arg.is_a? Figurine) ? "(c'est une figurine)" : "(ce n'est pas une figurine)")
        if arg.is_a? Figurine
          @unites << arg
        elsif arg.is_a? Arme
          @arsenal << arg
        elsif arg.respond_to? :values
          arg.values{|ar| self << ar}
        elsif arg.respond_to? :each
          arg.each{|ar| self << ar}
        else
          raise "Tentative d'ajout de truc inconnu : #{arg.inspect}"
        end
      end
    end

    def to_s
      chaine = @nom + "\n"
      @nom.size.times{|osef| chaine << '='}
      chaine << "\n\n"
#       max_size_unites = JetDes::max_size @unites
#       max_size_arsenal = JetDes::max_size @arsenal
      chaine << hash_to_s('Unités', @unites)
      chaine << hash_to_s('Arsenal', @arsenal)

      chaine
    end

#     def unite_to_s#affiche unite
#       hash_to_s
#       chaine << '  Unités' + "\n" + '  '
#       'Unités'.size.times{|osef| chaine << '-'}
#       chaine << "\n"
#       @unites.each_with_index{|unit, idx| chaine << "    #{idx} #{unit.nom}\n"}
#       chaine << "\n"
#     end
#
#     def arsenal_to_s #affiche arsenal
#       chaine << '  Armes' + "\n" + '  '
#       'Armes'.size.times{|osef| chaine << '-'}
#       chaine << "\n"
#       @arsenal.each_with_index{|arm, idx| chaine << "    #{idx} #{arm.nom}\n"}
#
#       chaine
#     end

    def hash_to_s titre, hash
      chaine = ''
      chaine << '  ' + titre + "\n" + '  '
      titre.size.times{|osef| chaine << '-'}
      chaine << "\n"
      hash.each_with_index{|arm, idx| chaine << "    #{idx} #{arm.nom}\n"}
      chaine << "\n"
      chaine
    end


  end

  class CapaciteSpeciale
    attr_accessor :nom, :phase, :arguments

    def initialize nom, phase, arguments
      @nom = nom
      @phase = phase
      @arguments = arguments
    end

    # A voir si reelement utile
    #   si utile alors peut être à voir si il ne faut pas copier arguments pour en avoir une autre instance.
    def copie
      p " je fais une copie de #{@nom}"
      CapaciteSpeciale.new @nom, @phase, @arguments
    end
  end

  class SituationUniteAttaquant
    attr_accessor :unite_attanquante, :cible, :modificateurs, :liste_situation

    attr_accessor :blessures_mortelles_par_salve, :degat_par_salve

    def initialize(unite_attanquante, cible, modificateurs = [])
      @unite_attanquante = unite_attanquante.copie
      @cible = cible.copie
      @modificateurs = modificateurs
      @liste_situation = []
      @unite_attanquante.figurines.each{|fig|@liste_situation << Situation.new(fig, fig.armes.first, @cible, @modificateurs)}
    end

    def proba court = false
      @blessures_mortelles_par_salve = 0
      @degat_par_salve = 0
      liste_situation.each{|situation| situation.proba court}
      liste_situation.each do |situation|
        @degat_par_salve += situation.degat_par_salve
        @blessures_mortelles_par_salve += situation.blessures_mortelles_par_salve
      end
      p "|| #{@unite_attanquante} qui attaque un(e) #{@cible.nom} fait #{(@degat_par_salve + @blessures_mortelles_par_salve).round(3)} dégats non sauvegardés par salve." + (@blessures_mortelles_par_salve > 0 ? "(dont #{@blessures_mortelles_par_salve} blessures mortelles)" : '') + " ||"
      p "=> Il faut #{(@cible.pv / (@degat_par_salve + @blessures_mortelles_par_salve)).round(3)} salve pour éliminer la cible."
    end

  end

  class Situation

    attr_accessor :attaquant, :cible, :arme, :modificateurs, :type, :blessures_mortelles_par_salve,
                  :touche_par_tir, :bless_par_touche, :proba_echec_sauvegarde, :degat_par_bless, :degat_par_salve

    def initialize(attaquant, arme, cible, modificateurs = [])
      @attaquant = attaquant.copie
      @cible = cible.copie
      @arme = arme.copie
      @modificateurs = modificateurs
      @blessures_mortelles_par_salve = 0
      @type = (@arme.class == ArmeCaC) ? 'CaC' : 'Tir'
    end

    def proba court = false


      modif_situation 'jet_touche'

      capacite_de_touche = (@type == 'CaC') ? @attaquant.cc : @attaquant.ct
      @touche_par_tir = JetDes::chance_succes_des(capacite_de_touche)

      modif_situation 'res_touche'

      modif_situation 'jet_blessure'

      force_attaque = (@type == 'CaC') ? (JetDes::force_cac(@attaquant, @arme)) : @arme.force
      @bless_par_touche = JetDes::chance_succes_des(JetDes::score_bless(force_attaque, @cible.endu))

      modif_situation 'res_blessure'

      @proba_echec_sauvegarde = JetDes::chance_echec_des(@cible.meilleur_save(@arme.pa))

      @degat_par_bless = @arme.degat_moyen * @proba_echec_sauvegarde

      nbr_attaque = (@type == 'CaC') ? @attaquant.attaque : @arme.attaque
      @degat_par_salve = nbr_attaque * @touche_par_tir * @bless_par_touche * @degat_par_bless

      modif_situation 'res_final'

      unless court
        p "touche_par_tir #{@touche_par_tir}"
        p "score_bless(#{force_attaque}, #{@cible.endu}) #{JetDes::score_bless(force_attaque, @cible.endu)}"
        p "bless_par_touche #{@bless_par_touche}"
        p "proba_echec_sauvegarde #{@proba_echec_sauvegarde}"
        p "degat_par_bless #{@degat_par_bless}"
        p "degat_par_salve #{degat_par_salve}"
      end

      p "|| Un(e) #{@attaquant.nom} qui attaque avec un(e) #{@arme.nom} sur un #{@cible.nom} fait #{(@degat_par_salve + @blessures_mortelles_par_salve).round(3)} dégats non sauvegardés par salve." + (@blessures_mortelles_par_salve > 0 ? "(dont #{@blessures_mortelles_par_salve} blessures mortelles)" : '') + " ||"
      p "=> Il faut #{(@cible.pv / (@degat_par_salve + @blessures_mortelles_par_salve)).round(3)} salve pour éliminer la cible."
    end

#     def proba_tir
#
#       modif_situation 'jet_touche'
#
#       @touche_par_tir = JetDes::chance_succes_des(@attaquant.ct)
#       p "touche_par_tir #{@touche_par_tir}"
#
#       modif_situation 'res_touche'
#
#       modif_situation 'jet_blessure'
#
#       @bless_par_touche = JetDes::chance_succes_des(JetDes::score_bless(@arme.force, @cible.endu))
#       p "score_bless(#{@arme.force}, #{@cible.endu}) #{JetDes::score_bless(@arme.force, @cible.endu)}"
#       p "bless_par_touche #{@bless_par_touche}"
#
#       modif_situation 'res_blessure'
#
#       @proba_echec_sauvegarde = JetDes::chance_echec_des(@cible.meilleur_save(@arme.pa))
#       p "proba_echec_sauvegarde #{@proba_echec_sauvegarde}"
#
#
#
#       @degat_par_bless = @arme.degat_moyen * @proba_echec_sauvegarde
#       p "degat_par_bless #{@degat_par_bless}"
#
#
#       @degat_par_salve = @arme.attaque * @touche_par_tir * @bless_par_touche * @degat_par_bless
#       p "degat_par_salve #{degat_par_salve}"
#
#
#       p "|| Un(e) #{@attaquant.nom} qui tir avec un(e) #{@arme.nom} sur un #{@cible.nom} fait #{(@degat_par_salve + @blessures_mortelles_par_salve).round(3)} dégats non sauvegardés par salve." + (@blessures_mortelles_par_salve > 0 ? "(dont #{@blessures_mortelles_par_salve} blessures mortelles)" : '') + " ||"
#       p "=> Il faut #{(@cible.pv / (@degat_par_salve + @blessures_mortelles_par_salve)).round(3)} salve pour éliminer la cible."
#     end
#
#     def proba_cac
#
#       modif_situation 'jet_touche'
#
#
#       @touche_par_tir = JetDes::chance_succes_des(@attaquant.cc)
#
#       modif_situation 'res_touche'
#
#       p "@touche_par_tir #{@touche_par_tir}"
#
#       modif_situation 'jet_blessure'
#
#       @bless_par_touche = JetDes::chance_succes_des(JetDes::score_bless(JetDes::force_cac(@attaquant, @arme), @cible.endu))
#
#       modif_situation 'res_blessure'
#
#       p "score_bless(#{JetDes::force_cac(@attaquant, @arme)}, #{@cible.endu}) #{JetDes::score_bless(JetDes::force_cac(@attaquant, @arme), @cible.endu)}"
#       p "bless_par_touche #{@bless_par_touche}"
#
#       @proba_echec_sauvegarde = JetDes::chance_echec_des(@cible.meilleur_save(@arme.pa))
#       p "proba_echec_sauvegarde #{@proba_echec_sauvegarde}"
#       @degat_par_bless = @arme.degat_moyen * @proba_echec_sauvegarde
#       p "degat_par_bless #{@degat_par_bless}"
#       @degat_par_salve = @attaquant.attaque * @touche_par_tir * @bless_par_touche * @degat_par_bless
#       p "degat_par_salve #{@degat_par_salve} (avec #{@attaquant.attaque} attaques)"
#
#       p "|| Un(e) #{@attaquant.nom} qui tappe avec un(e) #{@arme.nom} sur un #{@cible.nom} fait #{(@degat_par_salve+ @blessures_mortelles_par_salve).round(3)} dégats non sauvegardés par salve. ||"
#       p "  => Il faut #{(@cible.pv / @degat_par_salve).round(3)} salve pour éliminer la cible."
#     end

    def modif_situation phase
      [@attaquant, @cible, @arme].each do |element|
        next if element.capacites_speciales.empty?
        element.capacites_speciales.each do |capa|
          JetDes.send(capa['nom'], self, *capa['args'] ) if phase == capa['phase']
        end
      end
      @modificateurs.each do |modif|
        JetDes.send(modif['nom'], self, *modif['args'] ) if phase == modif['phase']
      end
    end
  end

  def self.proba_tir(tireur, arme_de_tir, cible)
    touche_par_tir = JetDes::chance_succes_des(tireur.ct)
    p "touche_par_tir #{touche_par_tir}"
    bless_par_touche = JetDes::chance_succes_des(JetDes::score_bless(arme_de_tir.force, cible.endu))
    p "score_bless(#{arme_de_tir.force}, #{cible.endu}) #{JetDes::score_bless(arme_de_tir.force, cible.endu)}"
    p "bless_par_touche #{bless_par_touche}"
    proba_echec_sauvegarde = JetDes::chance_echec_des(cible.meilleur_save(arme_de_tir.pa))
    p "proba_echec_sauvegarde #{proba_echec_sauvegarde}"
    degat_par_bless = arme_de_tir.degat_moyen * proba_echec_sauvegarde
    p "degat_par_bless #{degat_par_bless}"
    degat_par_salve = arme_de_tir.attaque * touche_par_tir * bless_par_touche * degat_par_bless
    p "degat_par_salve #{degat_par_salve}"

    p "|| Un(e) #{tireur.nom} qui tir avec un(e) #{arme_de_tir.nom} sur un #{cible.nom} fait #{degat_par_salve.round(3)} dégats non sauvegardés par salve. ||"
    p "  => Il faut #{(cible.pv / degat_par_salve).round(3)} salve pour éliminer la cible."
  end

  def self.proba_cac(combattant, arme_de_cac, cible)
    touche_par_attaque = JetDes::chance_succes_des(combattant.cc)
    #     p "touche_par_attaque #{touche_par_attaque}"
    bless_par_touche = JetDes::chance_succes_des(JetDes::score_bless(JetDes::force_cac(combattant, arme_de_cac), cible.endu))
    #     p "score_bless(#{force_cac(combattant, arme_de_cac)}, #{cible.endu}) #{JetDes::score_bless(JetDes::force_cac(combattant, arme_de_cac), cible.endu)}"
    #     p "bless_par_touche #{bless_par_touche}"
    proba_echec_sauvegarde = JetDes::chance_echec_des(cible.meilleur_save(arme_de_cac.pa))
    #     p "proba_echec_sauvegarde #{proba_echec_sauvegarde}"
    degat_par_bless = arme_de_cac.degat_moyen * proba_echec_sauvegarde
    #     p "degat_par_bless #{degat_par_bless}"
    degat_par_assaut = combattant.attaque * touche_par_attaque * bless_par_touche * degat_par_bless
    #     p "degat_par_assaut #{degat_par_assaut}"

    p "|| Un(e) #{combattant.nom} qui tappe avec un(e) #{arme_de_cac.nom} sur un #{cible.nom} fait #{degat_par_assaut.round(3)} dégats non sauvegardés par assaut. ||"
    p "  => Il faut #{(cible.pv / degat_par_assaut).round(3)} assaut pour éliminer la cible."
  end

  def self.simu_jet_des_tir(nbr_tirage, tireur, arme_de_tir, cible)
    nbr_touche = 0
    nbr_bless = 0
    nbr_non_save = 0
    cumul_degat = 0
    nbr_tirage.times do
      arme_de_tir.attaque.times do
        rand(1..6) >= tireur.ct ? nbr_touche += 1 : next
        rand(1..6) >= JetDes::score_bless(arme_de_tir.force, cible.endu) ? nbr_bless += 1 : next
        rand(1..6) < cible.meilleur_save(arme_de_tir.pa) ? nbr_non_save += 1 : next
        cumul_degat += arme_de_tir.degat
      end
    end
    p "Simulation pour un(e) #{tireur.nom} qui tir #{nbr_tirage} fois avec un(e) #{arme_de_tir.nom} sur un #{cible.nom}"
    p "  => #{nbr_touche} touches;  #{nbr_bless} blessures ; #{nbr_non_save} blessures non sauvegardées; #{cumul_degat} pv perdus; soit en moyenne, #{cumul_degat.to_f / nbr_tirage.to_f} pv par tir"
  end

  # Fait des tableaux de stat avec l'endurance de la cible en ordonnée et la sauvegarde en abscisse
  # Les valeurs dans les tableaux sont le nombre de blessures
  def self.proba_complete attaquant, arme, modificateur = []
    endurances = (1..8)
    sauvegardes = (2..7)
    sauvegardes_invu = (2..7)

    tableau_svg = []
    tableau_invu = []

    #tableau avec sauvegardes
    endurances.each_with_index do |endu, idx_endu|
      tableau_svg << []
      sauvegardes.each_with_index do |svg, idx_svg|
        cible =  Figurine.new("Cible endu #{endu}; svg #{svg}", 0, 0, 0, 0, endu, 0, 0, 0, svg)
        situation = Situation.new(attaquant, arme, cible, modificateur)
        situation.proba(true)
        tableau_svg[idx_endu] << situation.degat_par_salve
      end
    end

    #tableau avec invulnérable
    endurances.each_with_index do |endu, idx_endu|
      tableau_invu << []
      sauvegardes_invu.each_with_index do |invu, idx_invu|
        cible =  Figurine.new("Cible endu #{endu}; invu #{invu}", 0, 0, 0, 0, endu, 0, 0, 0, 7,invu)
        situation = Situation.new(attaquant, arme, cible, modificateur)
        situation.proba(true)
        tableau_invu[idx_endu] << situation.degat_par_salve
      end
    end

    #affichage
    separateur = ''
    (sauvegardes.size + 1).times {separateur << '-----------'}

    p separateur
    p separateur
    p "Proba complete pour un(e) #{attaquant} avec #{arme}"
    p ""

    premiere_ligne =  " endu/svg |"
    sauvegardes.each {|svg| premiere_ligne << "   S #{svg}+   |"}
    p premiere_ligne
    p separateur
    endurances.each_with_index do |endu, idx_endu|
      ligne = "    E#{endu}    |"
      sauvegardes.each_with_index do |svg, idx_svg|
        ligne << string_avec_caractere(tableau_svg[idx_endu][idx_svg], 5, 3)
        ligne << " |"
      end
      p ligne
      p separateur
    end

    p ""
    separateur = ''
    (sauvegardes_invu.size + 1).times {separateur << '-----------'}
    premiere_ligne =  " endu/invu|"
    sauvegardes_invu.each {|invu| premiere_ligne << "   S #{invu}++  |"}
    p premiere_ligne
    p separateur
    endurances.each_with_index do |endu, idx_endu|
      ligne = "    E#{endu}    |"
      sauvegardes_invu.each_with_index do |invu, idx_invu|
        ligne << string_avec_caractere(tableau_invu[idx_endu][idx_invu], 5, 3)
        ligne << " |"
      end
      p ligne
      p separateur
    end
  end

end


#########################################
####          capa_standard          ####
#########################################
arme_empoisonnee_4 = {'phase' => 'res_blessure', 'nom' => :arme_empoisonnee, 'args' => [4]}

insensible_5 = {'phase' => 'res_final', 'nom' => :insensible_a_la_douleur, 'args' => [5]}
insensible_6 = {'phase' => 'res_final', 'nom' => :insensible_a_la_douleur, 'args' => [6]}

moins_1_cc = {'phase' => 'jet_touche', 'nom' => :addition_caracteristique, 'args' => ['@attaquant', '@cc', -1]}
plus_1_attaque = {'phase' => 'jet_touche', 'nom' => :addition_caracteristique, 'args' => ['@attaquant', '@attaque', 1]}
plus_2_attaque = {'phase' => 'jet_touche', 'nom' => :addition_caracteristique, 'args' => ['@attaquant', '@attaque', 2]}
fois_2_attaque = {'phase' => 'jet_touche', 'nom' => :multiplication_caracteristique, 'args' => ['@attaquant', '@attaque', 2]}

relance_des_1_touche = {'phase' => 'res_touche', 'nom' => :relance_des_1, 'args' => ['@touche_par_tir']}
relance_des_1_bless = {'phase' => 'res_blessure', 'nom' => :relance_des_1, 'args' => ['@bless_par_touche']}
relance_complete_touche = {'phase' => 'res_touche', 'nom' => :relance_complete, 'args' => ['@touche_par_tir']}
relance_complete_bless = {'phase' => 'res_blessure', 'nom' => :relance_complete, 'args' => ['@bless_par_touche']}


#########################################
####            DRUKHARI             ####
#########################################
# cabalite = JetDes::Tireur.new('Cabalite', 3)
drukhari = JetDes::Faction.new('Drukhari')
drukhari << (cabalite = JetDes::Figurine.new('Cabalite', 7, 3, 3, 3, 3, 1, 1, 7, 5))
drukhari << succube = JetDes::Figurine.new('Succube', 8, 2, 2, 3, 3, 5, 4, 8, 6, 4)
drukhari << wyche = JetDes::Figurine.new('Wyche', 8, 3, 3, 3, 3, 1, 2, 7, 6, 6)
drukhari << grotesque = JetDes::Figurine.new('Grotesque', 7, 3, 6, 5, 5, 4, 4, 8, 6, 5)
drukhari << raider = JetDes::Figurine.new('Raider', 14, 4, 3, 6, 5, 10, 3, 7, 4, 5)
raider.mots_cles << 'vehicule'
drukhari << talos = JetDes::Figurine.new('Talos', 8, 3, 4, 6, 6, 7, 5, 8, 3, 5)

drukhari << canon_desintegrateur = JetDes::ArmeTir.new('Canon désintégrateur', 'Assaut', 3, 36, 5, -3, 2)
drukhari << lance_des_tenebres = JetDes::ArmeTir.new('Lance des ténèbres', 'Lourde', 1, 36, 8, -4, 'D6')
drukhari << fusil_eclateur_sur_vehicule = JetDes::ArmeTir.new('Fusil éclateur', 'Tir rapide', 1, 24, 5, 0, 1)
drukhari << fusil_eclateur = JetDes::ArmeTir.new('Fusil éclateur', 'Tir rapide', 2, 24, 1, 0, 1, [arme_empoisonnee_4])
drukhari << canon_eclateur = JetDes::ArmeTir.new('Canon éclateur', 'Tir rapide', 6, 36, 1, 0, 1, [arme_empoisonnee_4])
drukhari << fusil_disrupteur_sur_vehicule = JetDes::ArmeTir.new('Fusil disrupteur', 'Assaut', 2, 18, 4, -1, 1, [{'phase' => 'res_blessure', 'nom' => :capa_fusil_disrupteur, 'args' => []}])
drukhari << lance_de_feu = JetDes::ArmeTir.new('Lance de feu', 'Assaut', 1, 18, 6, -5, JetDes::proba_meilleur_jet(2,6))
drukhari << lacerateur_sur_vehicule = JetDes::ArmeTir.new('Lacérateur', 'Assaut', 3.5, 12, 6, -1, 1)

drukhari << vouge_de_sang = JetDes::ArmeCaC.new('Vouge de sang', '+3', -3, 'D3')
drukhari << lame_hekatari = JetDes::ArmeCaC.new('Lame Hekatari', 'utilisateur', 0, 1, [plus_1_attaque])
drukhari << gantlets_hydres = JetDes::ArmeCaC.new('Gantlets hydres', 'utilisateur', -1, 1, [plus_1_attaque, relance_complete_bless])
drukhari << epees_fouets = JetDes::ArmeCaC.new('Epées fouets', 'utilisateur', -1, 1,[plus_2_attaque,#C'est plus D3 attaque
                                                                         {'phase' => 'res_touche', 'nom' => :relance_complete, 'args' => ['@touche_par_tir']}])
drukhari << filet_et_empaleur = JetDes::ArmeCaC.new('Filet barbelé et empaleur', 'utilisateur', -1, 2,[plus_1_attaque])
drukhari << hachoir_monstreux = JetDes::ArmeCaC.new('Hachoir monstrueux', 'utilisateur', -2, 1, [plus_1_attaque])
drukhari << gantlets_talos = JetDes::ArmeCaC.new('Gantlets de Talos', '+2', -3, 'D3', [moins_1_cc])
drukhari << macro_scalpel = JetDes::ArmeCaC.new('Macro Scalpel', '+1', -2, 2)
drukhari << fleaux = JetDes::ArmeCaC.new('Fléaux', 'utilisateur', 0, 1, [relance_complete_bless, fois_2_attaque])


#########################################
####         ASTRA MILITARUM         ####
#########################################
# garde_imp = JetDes::Tireur.new('Imperial guard', 4)
astra_militarum = JetDes::Faction.new('Astra Militarum')
astra_militarum << garde_imp = JetDes::Figurine.new('Imperial guard', 6, 4, 4, 3, 3, 1, 1, 6, 5)
astra_militarum << russ = JetDes::Figurine.new('Leman Russ', 10, 6, 4, 7, 8, 12, 3, 7, 3)
russ.mots_cles << 'vehicule'
p russ.inspect
astra_militarum << chimere = JetDes::Figurine.new('Chimera', 12, 6, 4, 6, 7, 10, 3, 7, 3)
chimere.mots_cles << 'vehicule'
astra_militarum << bullgryn_mantlet = JetDes::Figurine.new('Bullgryn avec mantlet', 6, 3, 4, 5, 5, 3, 3, 7, 2)
astra_militarum << bullgryn_bouclier_brute = JetDes::Figurine.new('Bullgryn avec bouclier de brute', 6, 3, 4, 5, 5, 3, 3, 7, 4, 4)
astra_militarum << fusil_laser = JetDes::ArmeTir.new('Fusil laser', 'Tir rapide', 1, 24, 3, 0, 1)
astra_militarum << fusil_laser_x127 = JetDes::ArmeTir.new('Fusil laser', 'Tir rapide', 127, 24, 3, 0, 1)
astra_militarum << canon_laser = JetDes::ArmeTir.new('Canon laser', 'Lourde', 1, 48, 9, -3, 'D6')


#########################################
####               TAU               ####
#########################################
tau_empire = JetDes::Faction.new('Tau Empire')
tau_empire << crisis = JetDes::Tireur.new('Exo armure Crisis', 4)
tau_empire << commander_coldstar = JetDes::Figurine.new('Commander Coldstar', 20, 3, 2, 5, 5, 6, 4, 9, 3)
tau_empire << fusil_plasma_froid_tau = JetDes::ArmeTir.new('Fusil à plasma froid', 'Tir rapide', 1, 24, 6, -3, 1)
tau_empire << lance_missiles_tau = JetDes::ArmeTir.new('Nacelle de missiles', 'Assault', 2, 36, 7, -1, 'D3')
tau_empire << cyclo_eclateur_ion_std_tau = JetDes::ArmeTir.new('Cyclo éclateur à ion (non surchargé)', 'Assault', 3, 18, 7, -1, 1)
tau_empire << cyclo_eclateur_ion_surcharge_tau = JetDes::ArmeTir.new('Cyclo éclateur à ion (surchargé)', 'Assault', 3, 18, 8, -1, 'D3')



#########################################
####        IMPERIAL KNIGHT          ####
#########################################
imperial_knight = JetDes::Faction.new('Imperial Knight')
imperial_knight << castellan = JetDes::Figurine.new('Knight Castellan', 10, 4, 3, 8, 8, 28, 4, 9, 3)
castellan.mots_cles << 'vehicule'




#########################################
####            TYRANIDS             ####
#########################################
tyranids = JetDes::Faction.new('Tyranids')
tyranids << hive_tyrant = JetDes::Figurine.new('Hive tyrant ailé', 16, 2, 3, 6, 7, 12, 4, 10, 3, 4)


#########################################
####          DEATH GUARD            ####
#########################################
death_guard = JetDes::Faction.new('Death Guard')
death_guard << mortarion = JetDes::Figurine.new('Mortarion', 12, 2, 2, 8, 7, 18, 6, 10, 3, 4, 40, ['Monstre','Personnage'],[insensible_5])



#########################################
####             ESSAI               ####
#########################################

JetDes::Faction::liste_des_factions.each{|faction| puts faction}

JetDes::proba_tir(garde_imp, fusil_laser, raider)
JetDes::Situation.new(cabalite, canon_laser, russ, [relance_des_1_touche]).proba true
JetDes::Situation.new(wyche, gantlets_hydres, garde_imp).proba true

p "                   "

JetDes::Situation.new(succube, vouge_de_sang, castellan, [relance_des_1_touche]).proba true
JetDes::Situation.new(wyche, lame_hekatari, castellan, [relance_des_1_touche]).proba true
JetDes::Situation.new(wyche, epees_fouets, castellan, [relance_des_1_touche]).proba true
JetDes::Situation.new(wyche, gantlets_hydres, castellan, [relance_des_1_touche]).proba true
JetDes::Situation.new(wyche, lame_hekatari, garde_imp, [relance_des_1_touche]).proba true
JetDes::Situation.new(wyche, epees_fouets, garde_imp, [relance_des_1_touche]).proba true
JetDes::Situation.new(wyche, gantlets_hydres, garde_imp, [relance_des_1_touche]).proba true
JetDes::Situation.new(wyche, lame_hekatari, grotesque, [relance_des_1_touche]).proba true
JetDes::Situation.new(wyche, epees_fouets, grotesque, [relance_des_1_touche]).proba true
JetDes::Situation.new(wyche, gantlets_hydres, grotesque, [relance_des_1_touche]).proba true
JetDes::Situation.new(grotesque, hachoir_monstreux, russ).proba true
JetDes::Situation.new(grotesque, hachoir_monstreux, russ, [relance_complete_bless]).proba true
JetDes::Situation.new(talos, macro_scalpel, russ).proba true
JetDes::Situation.new(talos, gantlets_talos, russ).proba true
JetDes::Situation.new(talos, fleaux, russ).proba true

JetDes::Situation.new(cabalite, canon_desintegrateur, russ, [relance_des_1_touche]).proba true
JetDes::Situation.new(cabalite, lance_des_tenebres, russ, [relance_des_1_touche]).proba true

JetDes::Situation.new(cabalite, canon_desintegrateur, chimere, [relance_des_1_touche]).proba true
JetDes::Situation.new(cabalite, lance_des_tenebres, chimere, [relance_des_1_touche]).proba true
JetDes::Situation.new(cabalite, fusil_eclateur, hive_tyrant, [relance_des_1_touche]).proba false
JetDes::Situation.new(cabalite, fusil_eclateur, russ, [relance_des_1_touche]).proba false

p "                   "

JetDes::proba_complete(grotesque, hachoir_monstreux)
JetDes::proba_complete(grotesque, hachoir_monstreux, [relance_des_1_bless])

p "                   "
p "                   "
p "                   "

wyche_lame_hekatari = wyche.copie
wyche_lame_hekatari.armes << lame_hekatari.copie
wyche_gantelet = wyche.copie
wyche_gantelet.armes << gantlets_hydres.copie
wyche_filet_et_empaleur = wyche.copie
wyche_filet_et_empaleur.armes << filet_et_empaleur.copie

wyche_x_10_gantelet = JetDes::Unite.new
wyche_x_10_gantelet << wyche_lame_hekatari
wyche_x_10_gantelet << wyche_lame_hekatari
wyche_x_10_gantelet << wyche_lame_hekatari
wyche_x_10_gantelet << wyche_lame_hekatari
wyche_x_10_gantelet << wyche_lame_hekatari
wyche_x_10_gantelet << wyche_lame_hekatari
wyche_x_10_gantelet << wyche_lame_hekatari
wyche_x_10_gantelet << wyche_filet_et_empaleur
wyche_x_10_gantelet << wyche_gantelet
wyche_x_10_gantelet << wyche_gantelet

JetDes::SituationUniteAttaquant.new(wyche_x_10_gantelet, castellan,[relance_des_1_touche,plus_1_attaque]).proba true

cabalite_fusil = cabalite.copie
cabalite_fusil.armes << fusil_eclateur.copie
cabalite_lacerateur = cabalite.copie
cabalite_lacerateur.armes << lacerateur_sur_vehicule.copie
cabalite_canon = cabalite.copie
cabalite_canon.armes << canon_eclateur.copie
guerrier_x_20_anti_inf = JetDes::Unite.new
14.times {guerrier_x_20_anti_inf << cabalite_fusil}
4.times {guerrier_x_20_anti_inf << cabalite_lacerateur}
2.times {guerrier_x_20_anti_inf << cabalite_canon}

JetDes::SituationUniteAttaquant.new(guerrier_x_20_anti_inf, mortarion, []).proba true

cabalite_fusil = cabalite.copie
cabalite_fusil.armes << fusil_eclateur.copie
cabalite_disloqueur = cabalite.copie
cabalite_disloqueur.armes << lance_des_tenebres.copie
cabalite_lance = cabalite.copie
cabalite_lance.armes << lance_des_tenebres.copie
guerrier_x_20_anti_char = JetDes::Unite.new
14.times {guerrier_x_20_anti_char << cabalite_fusil}
4.times {guerrier_x_20_anti_char << cabalite_disloqueur}
2.times {guerrier_x_20_anti_char << cabalite_lance}

JetDes::SituationUniteAttaquant.new(guerrier_x_20_anti_char, mortarion, []).proba true

JetDes::Situation.new(cabalite, fusil_eclateur, mortarion).proba true
JetDes::Situation.new(cabalite, canon_eclateur, mortarion).proba true
JetDes::Situation.new(cabalite, lacerateur_sur_vehicule, mortarion).proba true
JetDes::Situation.new(cabalite, lance_des_tenebres, mortarion).proba true



# initialize(unite_attanquante, cible, modificateurs = [])

# JetDes::Situation.new(wyche, epees_fouets, garde_imp).proba_cac
# JetDes::Situation.new(wyche, lame_hekatari, garde_imp).proba_cac
# p "                   "
# JetDes::Situation.new(wyche, gantlets_hydres, bullgryn_mantlet).proba_cac
# JetDes::Situation.new(wyche, epees_fouets, bullgryn_mantlet).proba_cac
# JetDes::Situation.new(wyche, lame_hekatari, bullgryn_mantlet).proba_cac
# p "                   "
# JetDes::Situation.new(wyche, gantlets_hydres, russ).proba_cac
# JetDes::Situation.new(wyche, epees_fouets, russ).proba_cac
# JetDes::Situation.new(wyche, lame_hekatari, russ).proba_cac


#########################################################################################
#########################################################################################

# class Billy
#   def method_missing(method, *args)
#     p "method_missing(#{method}, #{args})"
#     12.send(method, *args)
#   end
#
#   def +(param)
#     p "+(#{param})"
#     12 + param
#   end
#
#   def coerce(other)
#     p "coerce(#{other})"
#     return self , other
#   end
# end
#
# bil = Billy.new
