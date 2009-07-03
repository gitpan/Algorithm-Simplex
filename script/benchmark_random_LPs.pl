#!/usr/bin/env perl
use Benchmark;
use PDL;
use Algorithm::Simplex;

=head1 Name

benchmark_random_LPs.pl - Benchmark the three models w/ random Linear Programs

=head1 Usage

perl benchmark_random_LPs.pl --rows 50 --columns 50 -n 50

=cut

use Getopt::Long;
use Algorithm::Simplex::Float;
use Algorithm::Simplex::PDL;
use Algorithm::Simplex::Rational;
use Data::Dumper;

my $rows          = 20;
my $columns       = 20;
my $number_of_LPs = 20;

GetOptions(
    'rows|r=i'          => \$rows,
    'columns|c=i'       => \$columns,
    'number_of_LPs|n=i' => \$number_of_LPs,
);

srand;
my $matrix = random_float_matrix( $rows, $columns, 1 );

timethese(
    $number_of_LPs,
    {
        float    => 'solve_LP("float")',
        piddle   => 'solve_LP("piddle")',
        rational => 'solve_LP("rational")',
    }
);

=cut head2 solve_LP

A function to step through a set of feasible solutions (tableaus) until
we reach an optimal solution or until we exceed a pre-defined number of steps.

=cut

sub solve_LP {
    my $model   = shift;
    my $tableau = matrix_copy($matrix);

    # extra step for piddles.
    $tableau = pdl $tableau if ( $model eq 'piddle' );

    my $tableau_object =
        $model eq 'float'    ? Algorithm::Simplex::Float->new($tableau)
      : $model eq 'piddle'   ? Algorithm::Simplex::PDL->new($tableau)
      : $model eq 'rational' ? Algorithm::Simplex::Rational->new($tableau)
      :   die "The model type: $model could not be found.";
    $tableau_object->set_number_of_rows_and_columns;
    $tableau_object->set_generic_variable_names_from_dimensions;

    # extra step for rationals (fracts)
    $tableau_object
      ->convert_natural_number_tableau_to_fractional_object_tableau
      if ( $model eq 'rational' );

    my $counter = 1;
    until ( $tableau_object->tableau_is_optimal ) {
        my ( $pivot_row_number, $pivot_column_number ) =
          $tableau_object->determine_bland_pivot_row_and_column_numbers;
        $tableau_object->pivot( $pivot_row_number, $pivot_column_number );
        $tableau_object->exchange_pivot_variables( $pivot_row_number,
            $pivot_column_number );
        $counter++;
        die "Too many loops" if ( $counter > 200 );
    }

}

sub random_float_matrix {

    # code to produce a matrix of random floats (or naturals)
    my $rows    = shift;
    my $columns = shift;
    my $natural_numbers;
    $natural_numbers = 0 unless $natural_numbers = shift;
    my $matrix;
    for my $i ( 0 .. $rows - 1 ) {
        for my $j ( 0 .. $columns - 1 ) {
            $matrix->[$i]->[$j] =
              $natural_numbers == 0 ? rand : int( 10 * rand );
        }
    }

    return $matrix;
}

sub random_pdl_matrix {

    # code to produce a random pdl matrix
    my $rows    = shift;
    my $columns = shift;
    my $matrix  = random( double, $rows, $columns );

    return $matrix;
}

sub matrix_copy {

    # code to copy matrix
    my $matrix = shift;
    my $matrix_copy;

    for my $i ( 0 .. $rows - 1 ) {
        for my $j ( 0 .. $columns - 1 ) {
            $matrix_copy->[$i]->[$j] = $matrix->[$i]->[$j];
        }
    }

    return $matrix_copy;
}
