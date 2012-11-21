#!/usr/bin/perl
sub find_rectangles {
	$_ = $_[0];
	my $width		= $_[3];
	my $height	 = $_[4];
	my $offset_x = $_[1] or 0;
	my $offset_y = $_[2] or 0;
	my @adjacent_points = ();
	my @string_lines		= split ("\n", $_);
	my %hlines					= ();
	my %vlines					= ();
	foreach my $i ( 0 .. $height) {
		if ($i == 0) {
		@{$adjacent_points[$i]} = ();
	}
	@{$adjacent_points[$i+1]} = ();
		foreach my $j ( 0 .. $width ) {
		my $value = 0;
		if ($j >= 1		 && 
		substr($string_lines[$i], $j - 1,	1) eq 'X') { $value += 1; }
		if ($j < $width && 
		substr($string_lines[$i], $j, 1)	eq 'X') { $value += 1; }
		if ($i == 0) {
		push @{ $adjacent_points[$i] }, $value;
		}
		else {
		$adjacent_points[$i][$j] += $value;
		}
		if ($adjacent_points[$i][$j] == 3) {
		$hlines{$i}++;
		$vlines{$j}++;
		}
		push @{ $adjacent_points[$i+1] }, $value;
		}
	}
	
	if (keys(%hlines) > 0 || keys(%vlines)) {
		%horizontals = ();
		%verticals	 = ();
		%adjacencies = ();
		%radjacencies= ();
		while (($key, $value) = each(%vlines)){
			if ($value > 1) {
				$verticals{$key} = 'NULL';
				@radjacencies{$key} = ();
		}
		}
		while (($key, $value) = each(%hlines)){
			if ($value > 1) {
				$horizontals{$key} = 'NULL';
				$distance{$key} = 0;
				@adjacencies{$key} = ();
				for my $j (keys(%verticals)) {
					if ($adjacent_points[$key][$j] > 2) {
						push @{$adjacencies{$key}}, $j;
						push @{$radjacencies{$j}}, $key;
					}
				}
			}
		}
		
		my @horizontals_final = ();
		my @verticals_final = ();

		if (keys(%horizontals) > 0 || keys(%verticals)) {			
				$infinity		= keys(%horizontals) + 100;
				# Pairs_G1 is now horizontals, Pairs_G2 is now	verticals, 
				# and adjacencies is now adjacencies. G1 and G2 can be accessed by keys,
				# but Pairs_G2[NULL] has to be handled specially.
				hopkroft_karp();
				while (($key,$value) = each(%horizontals)) {
				if ($value eq 'NULL') {	
					push @horizontals_final, $key ;
				}
				else {
					if ($#{$radjacencies{$value}} < $#{$adjacencies{$key}}) {
						push @verticals_final, $value;
					} else {
						push @horizontals_final, $key ;
					}
				}
			}
			while (($key,$value) = each(%verticals)) {
				if ($value eq 'NULL') {	
					push @verticals_final, $key;
				}
			}
		} else {
			@verticals_final = keys(%vlines);
			if (!$#verticals_final) {
				@horizontals_final = keys(%hlines);
			}
		}
		
		push @verticals_final, $width;
		push @horizontals_final, $height;
		
		my $partitions = $#verticals_final*$#horizontals_final;
		
		print "// Found $partitions partitions.\n";
		
		my $old_h = 0;
		my $old_v = 0;
		for my $h (sort {$a <=> $b} @horizontals_final) {
		for my $v (sort {$a <=> $b} @verticals_final) {
			my @string_lines_inner = @string_lines[$old_h..($h-1)];
			foreach my $string_line (@string_lines_inner) {
				$string_line = substr($string_line,$old_v,$v-$old_v);
			}
			find_rectangles(join("\n",@string_lines_inner),$offset_x + $old_v,$offset_y + $old_h,$v-$old_v,$h-$old_h);
			$old_v=$v;
		}
		$old_h = $h;
		}
	}
	else {
		while($_ = pop @string_lines) {
			if (/X/) {
				push @string_lines, $_;
				last;
			}
			$height--;
		}
		while ($_ = shift @string_lines) {
			if (/X/) {
				unshift @string_lines, $_;
				last;
			}
			$height--;
			$offset_y++;
		}
		if ($height > 0) {
			$_ = $string_lines[0];
			s/^\.*//;
			$offset_x = $offset_x + $width - length($_);
			s/\.*$//;
			$width    = length($_);
			if ($height == 1 && m/\./) {
				my $inner_quote = $_;
				$inner_quote =~ s/X*$//;
				while (length($inner_quote) > 0) {
					$_ = substr($_,length($inner_quote));
					find_rectangles($_,$offset_x + length($inner_quote), $offset_y, length($_), 1);
					$inner_quote =~ s/\.*$//;
					$_ = $inner_quote;
					$inner_quote =~ s/X*$//;
				}
				$width = length($_);
			}
			if ($width > 0) {
				print "\t\t{$offset_x, $offset_y, $width, $height},\n";
			}
		}
	}
}
sub hopkroft_karp {
	while (bfs()) {
		while (($key, $value) = each(%horizontals)) {
			if ($value eq 'NULL') {
				dfs($key);
			}
		}
	}
}
sub bfs {
	my @queue		 = ();
	while (($key, $value) = each(%horizontals)) {
		if ($value eq 'NULL') {
			$distance{$key} = 0;
			unshift @queue, $key;
		} else {
			$distance{$key} = $infinity;
		}
	}
	$distance{'NULL'} = $infinity;
	while ($#queue) {
		my $v = pop @queue;
		
		for $u (@{$adjacencies{$v}}) {
			if ($distance{$verticals{$u}} == $infinity) {
				$distance{$verticals{$u}} = $distance{v} + 1;
				unshift @queue, $verticals{$u};
			}
		}
	}
	if ($queue[0] eq 'NULL') { return 1;}
	return 0;
}
sub dfs {
	if ($_[0] eq 'NULL') {return 1;}
	for $u (@{$adjacencies{$_[0]}}) {
		if ($distance{$verticals{$u}} == $distance{$_[0]} + 1) {
			if (dfs($verticals{$u})) {
				$verticals{$u} = $_[0];
				$horizontals{$_[0]} = $u;
				return 1;
			}
		}
	}
	$distance{$_[0]} = $infinity;
	return 0;
}

$file_suffix = 0;
{
	local $/ = undef;
	$_			 = <>;
	s/\A.*?"//s;
	s/"\s*"//sg;
	s/\\377\\377\\377/./sg;
	s/\\0\\0\\0/X/sg;
	s/",\s*};//sg;
	s/(.{240})/\1\n/sg;
	print "namespace Pomeranian{\n\tconst Cairo.RectangleInt input_region[] = {\n";
	find_rectangles($_,0,0,240,240);
	print "\t}\n}"
}
