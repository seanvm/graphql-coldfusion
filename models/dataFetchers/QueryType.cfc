component {

    property name="starWarsData" inject="id";

    function hero( env, context ) {
        return variables.starWarsData.artoo;
    }

    function human( env, context ) {
        var id = arguments.environment.getArguments().get( "id" );
        if ( isNull( id ) ) {
            return;
        }
        return variables.starWarsData.humans[ id ];
    }

    function droid( env, context ) {
        var id = arguments.environment.getArguments().get( "id" );
        if ( isNull( id ) ) {
            return;
        }
        return variables.starWarsData.droids[ id ];
    }

}
