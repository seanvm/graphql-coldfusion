component {

    property name="wirebox" inject="wirebox";
    property name="controller" inject="coldbox";

    property name="schemas";
    property name="wirings";
    property name="types";

    function init() {
        variables.schemas = [];
        variables.wirings = {};
        variables.types = {};
        return this;
    }

    function addSchema( required schema ) {
        variables.schemas.append( arguments.schema );
        return this;
    }

    function addWiring( required string name, required struct wiring ) {
        variables.wirings[ arguments.name ] = arguments.wiring;
        return this;
    }

    function addWiringCFC( required cfc ) {
        if ( isSimpleValue( cfc ) ) {
            arguments.cfc = variables.wirebox.getInstance( dsl = arguments.cfc );
        }
        var md = controller.getUtil().getInheritedMetadata( arguments.cfc );
        var typeName = listLast( md.fullname, "." );
        param md.functions = [];
        var wiringFuncs = md.functions.reduce( function( acc, func ) {
            acc[ func.name ] = function( env ) {
                return invoke( cfc, func.name, { "environemnt" = env } );
            };
            return acc;
        }, {} );
        addWiring( typeName, wiringFuncs );
        return this;
    }

    function addTypeResolver( required string name, required resolver ) {
        variables.types[ arguments.name ] = arguments.resolver;
        return this;
    }

    function build() {
        var schemaGenerator = createObject( "java", "graphql.schema.idl.SchemaGenerator" ).init();
        var graphQLSchema = schemaGenerator.makeExecutableSchema( buildSchemaDefinition(), buildRuntimeWiring() );
        var executionStrategy = buildExecutionStrategy();

        return createObject( "java", "graphql.GraphQL" )
            .newGraphQL( graphQLSchema )
            .queryExecutionStrategy(executionStrategy)
            .mutationExecutionStrategy(executionStrategy)
            .build();

    }

    private function buildSchemaDefinition() {
        var schemaParser = createObject( "java", "graphql.schema.idl.SchemaParser" ).init();
        var typeDefinitionRegistry = createObject( "java", "graphql.schema.idl.TypeDefinitionRegistry" ).init();
        for ( var schema in variables.schemas ) {
            typeDefinitionRegistry.merge( schemaParser.parse( schema ) );
        }
        return typeDefinitionRegistry;
    }

    private function buildRuntimeWiring() {
        var runtimeWiring = createObject( "java", "graphql.schema.idl.RuntimeWiring" ).newRuntimeWiring();

        for ( var typeName in variables.wirings ) {
            var typeDefinitionStruct = variables.wirings[ typeName ];
            var typeRuntimeWiring = createObject( "java", "graphql.schema.idl.TypeRuntimeWiring" )
                .newTypeWiring( typeName );
            for ( var dataFetcherKeyName in typeDefinitionStruct ) {
                var fetcher = typeDefinitionStruct[ dataFetcherKeyName ];
                typeRuntimeWiring.dataFetcher( dataFetcherKeyName, createDynamicProxy(
                    new proxies.DataFetcher( fetcher ),
                    [ "graphql.schema.DataFetcher" ]
                ) );
            }
            runtimeWiring.type( typeRuntimeWiring );
        }

        for ( var typeName in variables.types ) {
            var resolver = variables.types[ typeName ];
            var typeRuntimeWiring = createObject( "java", "graphql.schema.idl.TypeRuntimeWiring" )
                .newTypeWiring( typeName )
                .typeResolver( createDynamicProxy(
                    new proxies.TypeResolver( resolver ),
                    [ "graphql.schema.TypeResolver" ]
                ) );
            runtimeWiring.type( typeRuntimeWiring );
        }

        return runtimeWiring.build();
    }

	private function buildExecutionStrategy(){
        return createObject("java", "graphql.execution.AsyncExecutionStrategy").init(
            createDynamicProxy(
                new proxies.ExceptionHandler(),
                [ "graphql.execution.DataFetcherExceptionHandler" ]
            )
        )
    }
}
