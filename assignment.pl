use strict;
use warnings;
use Text::CSV;

# Function to read CSV file and return data
sub read_csv {
    my ($filename) = @_;
    my $csv = Text::CSV->new({ binary => 1, auto_diag => 1, eol => $/ });
    open my $fh, "<:encoding(utf8)", $filename or die "$filename: $!";
    my $data = $csv->getline_all($fh);
    close $fh;
    return $data;
}

# Read CSV files
my $students_data = read_csv("students.csv");
my $parents_data = read_csv("parents.csv");
my $teachers_data = read_csv("teachers.csv");

# Data structures
my %students = map { $_->[0] => { homeroom => $_->[1], grade => $_->[2] } } @$students_data;
my %teachers = map { $_->[1] => $_->[0] } @$teachers_data;
my %parents;
my %parent_capacity;

# Parsing Parent Data
foreach my $row (@$parents_data) {
    my ($id, $name, $email, $classname, $required_students, $capacity, $location, $grades, @periods) = @$row;
    
    $parents{$id} = {
        name => $name,
        email => $email,
        classname => $classname,
        required_students => $required_students,
        location => $location,
        grades => $grades,
        periods => { map { $_ => $periods[$_-1] } 1..7 }
    };

    foreach my $period (1..7) {
        $parent_capacity{$id}{$period} = $capacity if $periods[$period-1];
    }
}

# Functions for the assignment logic
sub parse_required_students {
    my ($required_str) = @_;
    return [ split /,/, $required_str ];
}

sub pick_random_period_for_parent {
    my ($parent_id) = @_;
    my @available_periods = grep { $parent_capacity{$parent_id}{$_} > 0 } keys %{$parents{$parent_id}{periods}};

    return @available_periods ? $available_periods[int(rand(@available_periods))] : undef;
}

sub pick_parent_for_student {
    my ($student, $period) = @_;
    my $student_grade = $students{$student}{grade};
    my @suitable_parents;

    foreach my $parent_id (keys %parents) {
        next unless $parent_capacity{$parent_id}{$period} > 0;
        my $parent_grades = $parents{$parent_id}{grades};
        next unless $parent_grades =~ /$student_grade/ || $parent_grades eq 'all';

        push @suitable_parents, $parent_id;
    }

    return @suitable_parents ? $suitable_parents[int(rand(@suitable_parents))] : undef;
}

# Assign students to parent volunteers
sub assign_students {
    my %assignments;
    my %student_assigned_periods;

    foreach my $student (keys %students) {
        foreach my $parent_id (keys %parents) {
            my $required_students = parse_required_students($parents{$parent_id}{required_students});
            if (grep { $_ eq $student } @$required_students) {
                my $period = pick_random_period_for_parent($parent_id);
                if (defined $period) {
                    $assignments{$student}{$period} = $parent_id;
                    $student_assigned_periods{$student}{$period} = 1;
                    $parent_capacity{$parent_id}{$period}--;
                }
            }
        }

        # Assign remaining periods
        for my $period (1..7) {
            next if $student_assigned_periods{$student}{$period};

            my $parent_id = pick_parent_for_student($student, $period);
            if (defined $parent_id) {
                $assignments{$student}{$period} = $parent_id;
                $student_assigned_periods{$student}{$period} = 1;
                $parent_capacity{$parent_id}{$period}--;
            }
        }
    }

    return \%assignments;
}

my $assignments = assign_students();

# Generate Output
sub generate_output {
    my ($assignments) = @_;
    my $csv = Text::CSV->new({ binary => 1, eol => $/ });

    open my $fh, ">:encoding(utf8)", "output.csv" or die "output.csv: $!";
    $csv->print($fh, ["Parent ID", "Parent Email", "Classname", "Student Name", "Student Homeroom", "Student Grade", "Period Assigned", "Teacher Name", "Teacher Homeroom"]);

    foreach my $student (keys %$assignments) {
        foreach my $period (keys %{$assignments->{$student}}) {
            my $parent_id = $assignments->{$student}{$period};
            my $parent = $parents{$parent_id};
            my $student_data = $students{$student};
            my $teacher_name = $teachers{$student_data->{homeroom}} // '';

            $csv->print($fh, [
                $parent_id,
                $parent->{email},
                $parent->{classname},
                $student,
                $student_data->{homeroom},
                $student_data->{grade},
                $period,
                $teacher_name,
                $student_data->{homeroom}
            ]);
        }
    }

    close $fh;
}

generate_output($assignments);
