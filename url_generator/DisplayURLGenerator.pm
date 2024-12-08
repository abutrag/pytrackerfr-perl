package DisplayURLGenerator;

use strict;
use warnings;
use parent 'URLGeneratorBase'; # Hérite de URLGeneratorBase
use URI::Escape;
use open ':std', ':encoding(cp1252)';
binmode STDOUT, ":encoding(cp1252)";
binmode STDERR, ":encoding(cp1252)";

# Constructor
sub new {
    my ($class, $fichier_input) = @_;
    my $self = $class->SUPER::new($fichier_input);
    $self->{levier} = 'Display'; # Définit le nom du canal
    return $self;
}

# Valide les paramètres pour le levier Display
sub valider_parametres {
    my ($self, $params) = @_;
    my @parametres_obligatoires = qw(domaine_tracking site nom_support nom_campagne nom_emplacement nom_banniere format_banniere url_destination);

    # Nettoie les espaces blancs et gère les valeurs nulles
    foreach my $key (keys %$params) {
        $params->{$key} = defined $params->{$key} ? $params->{$key} =~ s/^\s+|\s+$//gr : '';
    }

    # Vérifie les paramètres manquants
    my @parametres_manquants = grep { !exists $params->{$_} || !$params->{$_} } @parametres_obligatoires;

    if (@parametres_manquants) {
        die "Paramètres obligatoires manquants: " . join(', ', @parametres_manquants) . "\n";
    }
}

# Ajuste les URLs pour des cas spécifiques comme Google, Amazon et Outbrain
sub ajuster_pour_cas_speciaux {
    my ($self, $params) = @_;
    my $nom_support = lc $params->{nom_support};

    if ($nom_support =~ /google/) {
        $params->{nom_support} = 'google-ads';
        $params->{prefixe_domaine} = 'https://ew3.io/c/a/';
        $params->{prefixe_domaine_impression} = 'https://ew3.io/v/a/';
    } elsif ($nom_support =~ /amazon/) {
        $params->{nom_support} = 'Amazon';
        $params->{prefixe_domaine} = 'https://ew3.io/c/a/';
        $params->{prefixe_domaine_impression} = 'https://ew3.io/v/a/';
    } elsif ($nom_support =~ /outbrain/) {
        $params->{nom_support} = 'Outbrain';
        $params->{prefixe_domaine} = 'https://ew3.io/c/a/';
        $params->{prefixe_domaine_impression} = 'https://ew3.io/v/a/';
    } else {
        $params->{prefixe_domaine} = "https://$params->{domaine_tracking}/dynclick/";
        $params->{prefixe_domaine_impression} = "https://$params->{domaine_tracking}/dynview/";
    }

    return $params;
}

# Génère les URLs pour le levier Display
sub generer_urls {
    my ($self, $params) = @_;

    # Nettoie les espaces blancs et gère les valeurs nulles
    foreach my $key (keys %$params) {
        $params->{$key} = defined $params->{$key} ? $params->{$key} =~ s/^\s+|\s+$//gr : '';
    }

    $params = $self->ajuster_pour_cas_speciaux($params);

    # Génère l'URL de suivi par paramètres
    my $url_parametres = sprintf(
        "%s?ead-publisher=%s&ead-name=%s-%s&ead-location=%s-%s&ead-creative=%s-%s&ead-creativetype=%s&eseg-name=%s&eseg-item=%s&ead-mediaplan=%s&ea-android-adid=%s&ea-ios-idfa=%s",
        $params->{url_destination}, $params->{nom_support}, $params->{nom_support}, $params->{nom_campagne},
        $params->{nom_emplacement}, $params->{format_banniere}, $params->{nom_banniere}, $params->{format_banniere}, $params->{format_banniere},
        $params->{nom_segment} // '', $params->{valeur_segment} // '', $params->{nom_plan_medias} // '',
        $params->{adid} // '', $params->{idfa} // ''
    );

    # Génère l'URL du pixel d'impression
    my $url_impression = sprintf(
        '<img src="%s%s/1x1.b?ead-publisher=%s&ead-name=%s-%s&ead-location=%s-%s&ead-creative=%s-%s&ead-creativetype=%s&eseg-name=%s&eseg-item=%s&ead-mediaplan=%s&ea-android-adid=%s&ea-ios-idfa=%s&ea-rnd=[RANDOM]" border="0" width="1" height="1" />',
        $params->{prefixe_domaine_impression}, $params->{site}, $params->{nom_support}, $params->{nom_support}, $params->{nom_campagne},
        $params->{nom_emplacement}, $params->{format_banniere}, $params->{nom_banniere}, $params->{format_banniere}, $params->{format_banniere},
        $params->{nom_segment} // '', $params->{valeur_segment} // '', $params->{nom_plan_medias} // '',
        $params->{adid} // '', $params->{idfa} // ''
    );

    return ($url_parametres, $url_impression);
}

# Traite le CSV pour le levier Display
sub process_csv {
    my ($self) = @_;
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });

    unless (-e $self->{fichier_input}) {
        print "Le fichier $self->{fichier_input} n'existe pas.\n";
        return;
    }

    open my $fh, "<:encoding(cp1252)", $self->{fichier_input}
        or die "Impossible d'ouvrir le fichier $self->{fichier_input}: $!";

    my $header = $csv->getline($fh);
    $csv->column_names(@$header);

    while (my $row = $csv->getline_hr($fh)) {
        eval {
            foreach my $key (keys %$row) {
                $row->{$key} = defined $row->{$key} ? $row->{$key} =~ s/^\s+|\s+$//gr : '';
            }

            $self->valider_parametres($row);
            my ($url_params, $url_impression) = $self->generer_urls($row);
            push @{$self->{urls}}, {
                'URL de Parametres'         => $url_params,
                'URL de Pixel d’Impression' => $url_impression,
            };
        };
        if ($@) {
            print "Erreur dans la ligne: $row->{id} - $@\n";
        }
    }

    close $fh;
    $self->ecrire_csv();
}

1; # Fin du module