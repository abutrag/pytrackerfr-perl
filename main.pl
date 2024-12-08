use strict;
use warnings;

use File::Spec;
use lib './url_generator'; # Ruta relativa al directorio de generadores
use DisplayURLGenerator;
use AffiliationURLGenerator;
use EmailingURLGenerator;
use CollaborationURLGenerator;
use ComparateurPreciosURLGenerator;
use GoogleAdsURLGenerator;
use BingAdsURLGenerator;
use SocialURLGenerator;

# Hash des templates CSV pour chaque levier
my %TEMPLATES_CSV = (
    dy => {
        headers   => "domaine_tracking,site,nom_support,nom_campagne,nom_emplacement,nom_banniere,format_banniere,nom_segment,valeur_segment,url_destination,adid,idfa",
        mandatory => "oui,oui,oui,oui,oui,oui,oui,non,non,oui,non,non",
        example   => "aaa1.client.com,client-com,amazon,été_2024,ROS,créa1,300x250,,,https://www.client.com?param=example,,",
    },
    af => {
        headers   => "domaine_tracking,site,nom_support,nom_campagne,nom_banniere,format_banniere,nom_segment,valeur_segment,url_destination,nom_plan_media,adid,idfa",
        mandatory => "oui,oui,oui,oui,oui,oui,non,non,oui,non,non,non",
        example   => "aaa1.client.com,client-com,awin,été_2024,créa1,300x250,,,https://www.client.com?param=example,,,",
    },
    em => {
        headers   => "domaine_tracking,site,nom_support,nom_campagne,email_utilisateur,nom_segment,valeur_segment,url_destination,nom_plan_media,id_client,adid,idfa",
        mandatory => "oui,oui,oui,oui,non,non,non,oui,non,non,non,non",
        example   => "aaa1.client.com,client-com,mailchimp,été_2024,,,,https://www.client.com?param=example,,,,,",
    },
    co => {
        headers   => "domaine_tracking,site,nom_support,nom_campagne,nom_emplacement,nom_banniere,format_banniere,nom_segment,valeur_segment,url_destination,adid,idfa",
        mandatory => "oui,oui,oui,oui,oui,oui,oui,non,non,oui,non,non",
        example   => "aaa1.client.com,client-com,partenaire,été_2024,ROS,créa1,300x250,,,https://www.client.com?param=example,,",
    },
    cp => {
        headers   => "domaine_tracking,site,nom_support,nom_campagne,nom_banniere,nom_segment,valeur_segment,url_destination,nom_plan_media,adid,idfa",
        mandatory => "oui,oui,oui,oui,non,non,non,oui,non,non,non,non",
        example   => "aaa1.client.com,client-com,comparateur,été_2024,,,,https://www.client.com?param=example,,,,,",
    },
    ga => {
        headers   => "domaine_tracking,site,nom_support,nom_campagne,nom_emplacement,nom_banniere,format_banniere,nom_segment,valeur_segment,url_destination,adid,idfa",
        mandatory => "oui,oui,oui,oui,oui,oui,oui,non,non,oui,non,non",
        example   => "aaa1.client.com,client-com,google-ads,été_2024,ROS,créa1,300x250,,,https://www.client.com?param=example,,",
    },
    ba => {
        headers   => "domaine_tracking,site,nom_support,nom_campagne,nom_emplacement,nom_banniere,format_banniere,nom_segment,valeur_segment,url_destination,adid,idfa",
        mandatory => "oui,oui,oui,oui,oui,oui,oui,non,non,oui,non,non",
        example   => "aaa1.client.com,client-com,bing-ads,été_2024,ROS,créa1,300x250,,,https://www.client.com?param=example,,",
    },
    sc => {
        headers   => "domaine_tracking,site,nom_support,nom_campagne,nom_emplacement,nom_banniere,format_banniere,nom_segment,valeur_segment,url_destination,nom_plan_media,adid,idfa",
        mandatory => "oui,oui,oui,oui,oui,oui,oui,non,non,oui,non,non",
        example   => "aaa1.client.com,client-com,facebook,été_2024,ROS,créa1,300x250,,,https://www.client.com?param=example,,,",
    },
    # Autres canaux à venir
);

sub afficher_template_csv {
    my ($levier) = @_;
    my $template = $TEMPLATES_CSV{$levier};

    if ($template) {
        print "\nVoici le template des en-têtes CSV attendu avec un exemple et les champs obligatoires pour ce levier.\n";
        print "\nEN-TÊTES: $template->{headers}\n";
        print "OBLIGATOIRES: $template->{mandatory}\n";
        print "EXEMPLE: $template->{example}\n\n";
    } else {
        print "Aucun template n'est disponible pour ce levier.\n";
    }
}

sub main {
    my ($levier_input, $fichier_input) = @_;

    unless ($levier_input) {
        print "Indiquez le nom du levier à traiter (dy pour Display, af pour Affiliation, em pour Emailing, co pour Collaboration, cp pour Comparateur de Prix, ga pour Google Ads, ba pour Bing Ads, sc pour Social): ";
        chomp($levier_input = <STDIN>);
    }

	my %map_levier = (
		dy => 'DisplayURLGenerator',
		af => 'AffiliationURLGenerator',
		em => 'EmailingURLGenerator',
		co => 'CollaborationURLGenerator',
		cp => 'ComparateurPreciosURLGenerator',
		ga => 'GoogleAdsURLGenerator',
		ba => 'BingAdsURLGenerator',
		sc => 'SocialURLGenerator',
	);


    unless (exists $map_levier{$levier_input}) {
        print "Levier introuvable. Veuillez utiliser le code correct.\n";
        return;
    }

    afficher_template_csv($levier_input);

    unless ($fichier_input) {
        print "Veuillez indiquer le chemin complet du fichier CSV (exemple: C:\\\\user\\\\desktop\\\\données.csv): ";
        chomp($fichier_input = <STDIN>);
    }

    unless (-e $fichier_input) {
        print "Le fichier $fichier_input n'existe pas.\n";
        return;
    }

    my $classe_generateur = $map_levier{$levier_input};
    eval "require $classe_generateur";
    die "Erreur lors du chargement du générateur $classe_generateur: $@" if $@;

    my $generateur = $classe_generateur->new($fichier_input);
    $generateur->process_csv();
}



main(@ARGV);