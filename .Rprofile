# Activate the R virtualenv
source(paste("renv", "activate.R", sep = .Platform$file.sep))


# Absolute path to project directory
project_path = function(project_dir="PPP-Table"){
    #' Returns the absolute project path string.
    #'   args: none
    #'   raises: error if <project_dir> is not within current wd absolute path.
    #'
    #' Author: ck
    current = getwd()
    path_sep = .Platform$file.sep
    dirs = strsplit(current, path_sep)[[1]]
    if (project_dir %in% dirs){
        i = which(dirs == project_dir)
        outpath = paste(dirs[1:i], collapse = path_sep)
        # TODO: add argument for appending sub-dirs
    } else {
        return(warning(paste(
            "Current working directory is not within the project path.",
            "The function 'project_path()' not defined.",
            sep = "\n")))
    }
    return(outpath)
}

# Add environments created for project
if (!suppressWarnings(readRenviron(paste(project_path(),
                                         "configs",
                                         ".Renviron",
                                         sep=.Platform$file.sep)))) {
    warning(paste("Could not read 'configs/.Renviron'.",
                  "There may be missing environment variables.",
                  sep = "\n"
    ))
}

# Create a database connection to a specific schema.
connection = function(username,
                      password,
                      schema,
                      host="192.168.2.12",
                      port=3306,
                      ssl_ca=NULL){
    #' Create database connection.
    #'     args: schema name, path to SSL cert, and user credentials
    #'     raises: none
    #'
    #' Author: ck
    require(RMariaDB)
    con = dbConnect(MariaDB(),
                    user = username,
                    host = host,
                    port = port,
                    password = password,
                    dbname = schema,
                    ssl.ca = ssl_ca
    )
}


# # Add functions above and project path to '.env' list
# .env = new.env()
# .env$project_dir = project_path()
# attach(.env)
