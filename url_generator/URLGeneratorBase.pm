package URLGeneratorBase;

use strict;
use warnings;
use Text::CSV;
use URI::Escape;
use POSIX qw(strftime);
use Carp;

# Constructor
sub new {
    my ($class, $fichier_input) = @_;
    my $self = {
        fichier_input => $fichier_input,
        urls          => [],
        levier        => 'default_channel', # Nombre del canal, puede cambiarse dinámicamente
    };
    bless $self, $class;
    return $self;
}

# Métodos abstractos
sub valider_parametres {
    croak "La méthode valider_parametres doit être implémentée dans une sous-classe.";
}

sub generer_urls {
    croak "La méthode generer_urls doit être implémentée dans une sous-classe.";
}

# Encodage d'une URL
sub encoder_url {
    my ($self, $url) = @_;
    return uri_escape($url);
}

# Traitement du CSV
sub traiter_csv {
    my ($self) = @_;
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1 });

    unless (-e $self->{fichier_input}) {
        print "Le fichier $self->{fichier_input} n'existe pas.\n";
        return;
    }

    open my $fh, "<:encoding(utf-8)", $self->{fichier_input}
        or die "Impossible d'ouvrir le fichier $self->{fichier_input}: $!";

    my $header = $csv->getline($fh);
    $csv->column_names(@$header);

    while (my $row = $csv->getline_hr($fh)) {
        eval {
            # Nettoyage des espaces blancs et gestion des valeurs nulles
            foreach my $key (keys %$row) {
                $row->{$key} = defined $row->{$key} ? $row->{$key} =~ s/^\s+|\s+$//gr : '';
            }

            # Validation et traitement des paramètres
            $self->valider_parametres($row);
            my ($url_params, $url_impression) = $self->generer_urls($row);
            push @{$self->{urls}}, {
                'URL de Parametres'         => $url_params,
                'URL de Pixel d\'Impression' => $url_impression,
            };
        };
        if ($@) {
            print "Erreur dans la ligne: $row->{id} - $@\n";
        }
    }

    close $fh;
    $self->ecrire_csv();
}

# Génération du nom de fichier
sub generer_nom_fichier_sortie {
    my ($self) = @_;
    my $timestamp = strftime "%Y_%m_%d_%H_%M_%S", localtime;
    return "${timestamp}_urls_$self->{levier}_generees.csv";
}

# Ecriture du CSV
sub ecrire_csv {
    my ($self) = @_;
    my $fichier_sortie = $self->generer_nom_fichier_sortie();
    my $csv = Text::CSV->new({ binary => 1, eol => $/ });

    # Abre el archivo en ANSI
    open my $fh, ">:encoding(cp1252)", $fichier_sortie
        or die "Impossible d'écrire dans le fichier $fichier_sortie: $!";

    # Escribe las cabeceras
    $csv->say($fh, ['URL de Parametres', 'URL de Pixel d\'Impression']);

    # Escribe las filas generadas
    foreach my $url (@{$self->{urls}}) {
        $csv->say($fh, [
            $url->{'URL de Parametres'},
            $url->{'URL de Pixel d\'Impression'},
        ]);
    }

    close $fh;
    print "Les URLs générées ont été enregistrées dans $fichier_sortie.\n";
}


1; # Fin du module