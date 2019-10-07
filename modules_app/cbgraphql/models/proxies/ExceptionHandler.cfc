/**
 * This is called when an exception is thrown during {@link graphql.schema.DataFetcher#get(DataFetchingEnvironment)} execution
 */
component {

    function init( ) {
        return this;
    }

    /**
     * When an exception during a call to a {@link DataFetcher} then this handler
     * is called back to shape the error that should be placed in the list of errors
     *
     * @param handlerParameters the parameters to this callback
     *
     * @return a result that can contain custom formatted {@link graphql.GraphQLError}s
     */
    function onException( handlerParameters ) {
        return arguments.handlerParameters.getException();
    }

}