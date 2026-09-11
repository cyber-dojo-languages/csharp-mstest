// The Main that starts MSTest.
//
// With EnableMSTestRunner an MSTest project is an executable rather than
// something a separate runner loads, and its entry point is written during
// the build by an MSBuild task. A kata here never starts MSBuild, so the
// entry point has to come from somewhere else, and this is it: compiled into
// the kata's assembly alongside the learner's own files.
//
// The generated one calls SelfRegisteredExtensions, which MSBuild writes
// beside it and which registers whatever optional extensions the project
// referenced, code coverage among them. Nothing here references any, so this
// registers the test framework and nothing else.

internal static class MSTestEntryPoint
{
    public static async System.Threading.Tasks.Task<int> Main(string[] args)
    {
        var builder = await global::Microsoft.Testing.Platform.Builder.TestApplication
            .CreateBuilderAsync(args);

        global::Microsoft.VisualStudio.TestTools.UnitTesting.TestingPlatformBuilderHook
            .AddExtensions(builder, args);

        using var app = await builder.BuildAsync();
        return await app.RunAsync();
    }
}
