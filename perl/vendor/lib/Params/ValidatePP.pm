package    # hide from PAUSE
    Params::Validate;

our $VERSION = '1.24';

BEGIN { $ENV{PARAMS_VALIDATE_IMPLEMENTATION} = 'PP' }
use Params::Validate;

1;
