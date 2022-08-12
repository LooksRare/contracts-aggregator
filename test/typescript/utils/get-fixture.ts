import * as fs from "fs";
import * as path from "path";

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export default (filename: string): any =>
  JSON.parse(fs.readFileSync(path.join(__dirname, `../fixtures/${filename}`), { encoding: "utf8", flag: "r" }));
