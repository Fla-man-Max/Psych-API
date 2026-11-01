import funkin.util.macro.GitCommit;

/** Invoked by TestSourceArchive.ps1 against the actual source metadata implementation. */
class SourceArchiveMetadata
{
  static function main():Void
  {
    var commit = GitCommit.getGitCommitHash();
    var branch = GitCommit.getGitBranch();
    if (commit != 'unknown') throw 'Source archive commit must be unknown, got: ' + commit;
    if (branch != 'source') throw 'Source archive branch must be source, got: ' + branch;
    if (GitCommit.getGitHasLocalChanges()) throw 'Source archives have no Git working-tree modifications';
    Sys.println('PASS: source archive metadata does not require Git history');
  }
}
