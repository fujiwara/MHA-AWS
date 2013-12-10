requires 'perl', '5.008001';

requires 'Log::Minimal';
requires 'AWS::CLIWrapper';
requires 'JSON';
requires 'Moo';
requires 'parent';
requires 'Pod::Usage';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
