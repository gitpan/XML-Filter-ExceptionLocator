package XML::Filter::ExceptionLocator;
use 5.006;
use strict;
use warnings;
our $VERSION = '1.00';

use base 'XML::SAX::Base';

# from XML::Filter::XInclude
sub set_document_locator {
    my ($self, $locator) = @_;
    push @{$self->{locators} ||= []}, $locator;
    
    $self->SUPER::set_document_locator($locator);
}

# install handler for all SAX methods
BEGIN {
    for my $method qw(start_document     end_document           start_element
                      end_element        processing_instruction comment
                      skipped_entity     ignorable_whitespace   end_entity
                      start_entity       entity_reference
                      start_cdata        end_cdata) {
        no strict 'refs';
        my $super_meth = "SUPER::$method";
        *{__PACKAGE__ . "::$method"} = 
          sub { 
              my $self = shift;

              # call method in expected context
              my $wantarray = wantarray;
              my (@ret, $ret);
              if ($wantarray) {
                  eval { @ret = $self->$super_meth(@_); };
              } else {
                  eval { $ret = $self->$super_meth(@_); };
              }

              # handle errors
              my $err = $@;
              if ($err and ref($err) and $err->isa('XML::SAX::Exception')) {
                  # it's showtime, add in Line/Col
                  if ($self->{locators} and @{$self->{locators}}) {
                      $err->{LineNumber}   = $self->{locators}[-1]->{LineNumber};
                      $err->{ColumnNumber} = $self->{locators}[-1]->{ColumnNumber};
                  }
                  die $err;
              } elsif ($err) {
                  die $err;
              }

              return @ret if $wantarray;
              return $ret;
          }
      }
}             

1;
__END__

=head1 NAME

XML::Filter::ExceptionLocator - filter to add line/col numbers to SAX errors

=head1 SYNOPSIS

  use XML::Filter::ExceptionLocator;
  use XML::SAX::ParserFactory;

  # parse some.xml adding line/col numbers to any errors that get
  # thrown from $whatever
  my $filter = XML::Filter::ExceptionLocator->new(Handler => $whatever);
  my $parser = XML::SAX::ParserFactory->parser(Handler => $filter);
  eval { $parser->parse_uri('some.xml'); }

  # the error object will have LineNumber and ColumnNumber now
  if ($@ and ref $@ and $@->isa('XML::SAX::Exception')) {
     print "Your error is at line $@->{LineNumber}, col $@->{ColumnNumber}\n";
  }

  # if you print the error the line and column are included
  print $@;

=head1 DESCRIPTION

This module implements a SAX filter which adds line-numbers and
column-numbers to errors generated by SAX handlers futher down the
pipeline.  I wrote this module so that
L<XML::Validator::Schema|XML::Validator::Schema> could blame the
correct line of XML for validation failures.

B<NOTE:> This module requires a SAX parser which correctly supports
the set_document_locator() call.  At present there is just one,
L<XML::SAX::ExpatXS|XML::SAX::ExpatXS>.  If you've got a number of
XML::SAX parsers installed and you want to make sure XML::SAX::ExpatXS
is used, do this:

   $XML::SAX::ParserPackage = 'XML::SAX::ExpatXS';

=head1 BUGS

Please use C<rt.cpan.org> to report bugs in this module:

  http://rt.cpan.org

=head1 SUPPORT

This module is supported on the perl-xml mailing-list.  Please join
the list if you have questions, suggestions or patches:

  http://listserv.activestate.com/mailman/listinfo/perl-xml

=head1 CVS

If you'd like to help develop this module you'll want to check out a
copy of the CVS tree:

  http://sourceforge.net/cvs/?group_id=89764

=head1 AUTHOR

Sam Tregar <sam@tregar.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Sam Tregar

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

=head1 SEE ALSO

L<XML::Validator::Schema|XML::Validator::Schema>

=cut