component {

    property name="StarWarsData" inject="id";

    function index( event, rc, prc ) {

        var cbGraphQLClient = getInstance( "ClientBuilder@cbGraphQL" )
            .addContext(arguments.prc)
            .addSchema( fileRead( expandPath( "/resources/graphql/starwars.graphql" ) ) )
            .addWiringCFC( "QueryType" )
            // .addWiring( "QueryType", {
            //     "hero" = function( env ) {
            //         return variables.artoo;
            //     },
            //     "human" = function( env ) {
            //         var id = arguments.environment.getArguments().get( "id" );
            //         if ( isNull( id ) ) {
            //             return;
            //         }
            //         return variables.humans[ id ];
            //     },
            //     "droid" = function( env ) {
            //         var id = arguments.environment.getArguments().get( "id" );
            //         if ( isNull( id ) ) {
            //             return;
            //         }
            //         return variables.droids[ id ];
            //     }
            // } )
            .addWiring( "Human", {
                "friends" = getFriendsDataFetcher()
            } )
            .addWiring( "Droid", {
                "friends" = getFriendsDataFetcher()
            } )
            .addTypeResolver( "Character", function( env ) {
                var id = arguments.env.getObject().get( "id" );
                if ( variables.starWarsData.humans.keyExists( id ) ) {
                    return env.getSchema().getObjectType( "Human" );
                }
                if ( variables.starWarsData.droids.keyExists( id ) ) {
                    return env.getSchema().getObjectType( "Droid" );
                }
                return;
            } )
            .build();

        var body = event.getHTTPContent( json = true );
        if ( ! isStruct( body ) ) {
            event.renderData(
                type = "json",
                statusCode = 500,
                data = {
                    "errors": "Invalid body. Received [#body#]"
                }
            );
            return;
        }
        var executionResult = cbGraphQLClient.execute( body.query );

        if ( executionResult.isDataPresent() ) {
            event.renderData(
                type = "json",
                statusCode = 200,
                data = executionResult.getData()
            );
        } else {
            event.renderData(
                type = "json",
                statusCode = 500,
                data = {
                    "errors": arrayMap( executionResult.getErrors(), function( error ) {
                        return error.getMessage();
                    } )
                }
            );
        }

    }

    private function getFriendsDataFetcher() {
        return function( environment ) {
            var friends = [];
            for ( var id in arguments.environment.getSource().get( "friends" ) ) {
                var character = getCharacter( id );
                if ( ! isNull( character ) ) {
                    friends.append( character );
                }
            }
            return friends;
        };
    }

    private function getCharacter( required string id ) {
        if ( variables.starWarsData.humans.keyExists( id ) ) {
            return variables.starWarsData.humans[ id ];
        }

        if ( variables.starWarsData.droids.keyExists( id ) ) {
            return variables.starWarsData.droids[ id ];
        }

        return;
    }

}
